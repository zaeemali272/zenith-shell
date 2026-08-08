#!/usr/bin/env python3
import sys
import os
import json
import urllib.request
import urllib.error
import ssl
import threading

CONFIG_DIR = os.path.expanduser("~/.config/zenith")
KEYS_FILE = os.path.join(CONFIG_DIR, "ai_keys.json")

def ensure_config_dir():
    os.makedirs(CONFIG_DIR, exist_ok=True)

def load_stored_keys():
    if os.path.exists(KEYS_FILE):
        try:
            with open(KEYS_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def save_stored_key(provider, key_value):
    ensure_config_dir()
    keys = load_stored_keys()
    keys[provider.lower()] = key_value.strip()
    with open(KEYS_FILE, "w", encoding="utf-8") as f:
        json.dump(keys, f, indent=2)
    return KEYS_FILE

def get_api_key(provider):
    keys = load_stored_keys()
    p_lower = provider.lower()
    if p_lower in keys and keys[p_lower]:
        return keys[p_lower]
    
    # Fallback to environment variables
    env_vars = {
        "gemini": "GEMINI_API_KEY",
        "claude": "ANTHROPIC_API_KEY",
        "groq": "GROQ_API_KEY"
    }
    env_name = env_vars.get(p_lower, "")
    if env_name:
        return os.environ.get(env_name, "").strip()
    return ""

def emit_event(event_type, **kwargs):
    payload = {"type": event_type}
    payload.update(kwargs)
    sys.stdout.write(json.dumps(payload) + "\n")
    sys.stdout.flush()

def check_keys():
    gemini_key = get_api_key("gemini")
    anthropic_key = get_api_key("claude")
    groq_key = get_api_key("groq")
    ollama_host = os.environ.get("OLLAMA_HOST", "http://localhost:11434").strip()

    ollama_available = False
    try:
        req = urllib.request.Request(f"{ollama_host}/api/tags", headers={"User-Agent": "Zenith-AI-Agent"})
        with urllib.request.urlopen(req, timeout=1.5) as resp:
            if resp.status == 200:
                ollama_available = True
    except Exception:
        ollama_available = False

    emit_event("keys_status", 
               gemini=bool(gemini_key),
               claude=bool(anthropic_key),
               groq=bool(groq_key),
               ollama=ollama_available,
               keys_file=KEYS_FILE)

def process_file_attachments(content):
    words = content.split()
    attached_contents = []
    clean_words = []

    for word in words:
        path_to_read = None
        if word.startswith("@file:"):
            path_to_read = word[6:]
        elif word.startswith("@file"):
            path_to_read = word[5:]
        elif word.startswith("@/") or word.startswith("@~"):
            path_to_read = word[1:]

        if path_to_read:
            path_to_read = os.path.expanduser(path_to_read.strip())
            if os.path.isfile(path_to_read):
                try:
                    with open(path_to_read, "r", encoding="utf-8", errors="ignore") as f:
                        file_text = f.read()
                    attached_contents.append(f"\n--- Attached File ({path_to_read}) ---\n{file_text}\n--- End of File ---")
                    clean_words.append(f"[Attached: {os.path.basename(path_to_read)}]")
                except Exception as e:
                    clean_words.append(f"[Error reading {path_to_read}: {str(e)}]")
            else:
                clean_words.append(f"[File not found: {path_to_read}]")
        else:
            clean_words.append(word)

    final_text = " ".join(clean_words)
    if attached_contents:
        final_text += "\n" + "\n".join(attached_contents)
    return final_text

def stream_gemini(messages, system_prompt="", specific_model=None):
    api_key = get_api_key("gemini")
    if not api_key:
        emit_event("error", message="GEMINI_API_KEY is not configured.\nUse `/key gemini <YOUR_API_KEY>` or set GEMINI_API_KEY environment variable.")
        return

    # Dynamic model candidates order: latest / pro / flash fallbacks
    if specific_model:
        models_to_try = [specific_model]
    else:
        models_to_try = [
            "gemini-2.5-flash",
            "gemini-1.5-pro",
            "gemini-2.0-flash",
            "gemini-1.5-flash"
        ]

    contents = []
    for msg in messages:
        role = "user" if msg.get("role") == "user" else "model"
        raw_text = msg.get("content", "")
        if msg.get("role") == "user":
            raw_text = process_file_attachments(raw_text)
        contents.append({
            "role": role,
            "parts": [{"text": raw_text}]
        })

    payload = {"contents": contents}
    if system_prompt:
        payload["systemInstruction"] = {
            "parts": [{"text": system_prompt}]
        }

    body = json.dumps(payload).encode("utf-8")
    ctx = ssl.create_default_context()

    last_err = None
    for model_name in models_to_try:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:streamGenerateContent?alt=sse&key={api_key}"
        req = urllib.request.Request(url, data=body, headers={
            "Content-Type": "application/json"
        }, method="POST")

        tokens_received = 0
        try:
            with urllib.request.urlopen(req, context=ctx, timeout=60) as resp:
                for line in resp:
                    line_str = line.decode("utf-8").strip()
                    if line_str.startswith("data: "):
                        json_data = line_str[6:].strip()
                        if not json_data:
                            continue
                        try:
                            data = json.loads(json_data)
                            candidates = data.get("candidates", [])
                            if candidates:
                                parts = candidates[0].get("content", {}).get("parts", [])
                                for p in parts:
                                    text = p.get("text", "")
                                    if text:
                                        tokens_received += 1
                                        emit_event("token", content=text)
                        except Exception:
                            pass
            if tokens_received > 0:
                emit_event("done")
                return
        except urllib.error.HTTPError as e:
            err_body = e.read().decode("utf-8", errors="ignore")
            last_err = f"HTTP {e.code}"
            # If 429 (quota) or 404 (not found), try next fallback model
            if e.code in (429, 404) and len(models_to_try) > 1 and model_name != models_to_try[-1]:
                continue
            else:
                # Parse human friendly error message
                friendly_msg = f"Gemini API Error ({model_name}): HTTP {e.code}"
                try:
                    err_json = json.loads(err_body)
                    msg_text = err_json.get("error", {}).get("message", "")
                    if "Quota exceeded" in msg_text or e.code == 429:
                        friendly_msg = f"⚠️ Gemini API Quota Exceeded (429) on `{model_name}`.\nIf using free tier, rate limit was reached. Check billing/plan or use `/key gemini <PRO_API_KEY>`."
                    else:
                        friendly_msg = f"⚠️ Gemini Error on `{model_name}`: {msg_text}"
                except Exception:
                    pass
                emit_event("error", message=friendly_msg)
                return
        except Exception as e:
            last_err = str(e)
            if len(models_to_try) > 1 and model_name != models_to_try[-1]:
                continue
            emit_event("error", message=f"Gemini API Error ({model_name}): {str(e)}")
            return

    emit_event("error", message=f"Gemini API Error: Rate limit/Quota reached across all models. ({last_err})")

def stream_claude(messages, system_prompt=""):
    api_key = get_api_key("claude")
    if not api_key:
        emit_event("error", message="ANTHROPIC_API_KEY is not configured.\nUse `/key claude <YOUR_API_KEY>` or set ANTHROPIC_API_KEY environment variable.")
        return

    url = "https://api.anthropic.com/v1/messages"
    
    formatted_msgs = []
    for msg in messages:
        role = "user" if msg.get("role") == "user" else "assistant"
        raw_text = msg.get("content", "")
        if msg.get("role") == "user":
            raw_text = process_file_attachments(raw_text)
        formatted_msgs.append({"role": role, "content": raw_text})

    payload = {
        "model": "claude-3-5-sonnet-20241022",
        "max_tokens": 4096,
        "messages": formatted_msgs,
        "stream": True
    }
    if system_prompt:
        payload["system"] = system_prompt

    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=body, headers={
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
    }, method="POST")

    ctx = ssl.create_default_context()
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=60) as resp:
            for line in resp:
                line_str = line.decode("utf-8").strip()
                if line_str.startswith("data: "):
                    json_data = line_str[6:].strip()
                    if not json_data:
                        continue
                    try:
                        data = json.loads(json_data)
                        evt_type = data.get("type")
                        if evt_type == "content_block_delta":
                            delta = data.get("delta", {})
                            if delta.get("type") == "text_delta":
                                text = delta.get("text", "")
                                if text:
                                    emit_event("token", content=text)
                    except Exception:
                        pass
        emit_event("done")
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8", errors="ignore")
        emit_event("error", message=f"Claude API Error: HTTP {e.code}")
    except Exception as e:
        emit_event("error", message=f"Claude API Error: {str(e)}")

def stream_groq(messages, system_prompt=""):
    api_key = get_api_key("groq")
    if not api_key:
        emit_event("error", message="GROQ_API_KEY is not configured.\nUse `/key groq <YOUR_API_KEY>` or set GROQ_API_KEY environment variable.")
        return

    url = "https://api.groq.com/openai/v1/chat/completions"
    
    formatted_msgs = []
    if system_prompt:
        formatted_msgs.append({"role": "system", "content": system_prompt})
    for msg in messages:
        raw_text = msg.get("content", "")
        if msg.get("role") == "user":
            raw_text = process_file_attachments(raw_text)
        formatted_msgs.append({"role": msg.get("role", "user"), "content": raw_text})

    payload = {
        "model": "llama-3.3-70b-versatile",
        "messages": formatted_msgs,
        "stream": True
    }

    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=body, headers={
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }, method="POST")

    ctx = ssl.create_default_context()
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=60) as resp:
            for line in resp:
                line_str = line.decode("utf-8").strip()
                if line_str.startswith("data: "):
                    json_data = line_str[6:].strip()
                    if json_data == "[DONE]":
                        break
                    if not json_data:
                        continue
                    try:
                        data = json.loads(json_data)
                        choices = data.get("choices", [])
                        if choices:
                            delta = choices[0].get("delta", {})
                            text = delta.get("content", "")
                            if text:
                                emit_event("token", content=text)
                    except Exception:
                        pass
        emit_event("done")
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8", errors="ignore")
        emit_event("error", message=f"Groq API Error: HTTP {e.code}")
    except Exception as e:
        emit_event("error", message=f"Groq API Error: {str(e)}")

def stream_ollama(messages, system_prompt=""):
    host = os.environ.get("OLLAMA_HOST", "http://localhost:11434").strip()
    url = f"{host}/api/chat"

    formatted_msgs = []
    if system_prompt:
        formatted_msgs.append({"role": "system", "content": system_prompt})
    for msg in messages:
        raw_text = msg.get("content", "")
        if msg.get("role") == "user":
            raw_text = process_file_attachments(raw_text)
        formatted_msgs.append({"role": msg.get("role", "user"), "content": raw_text})

    payload = {
        "model": "llama3",
        "messages": formatted_msgs,
        "stream": True
    }

    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=body, headers={
        "Content-Type": "application/json"
    }, method="POST")

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            for line in resp:
                line_str = line.decode("utf-8").strip()
                if not line_str:
                    continue
                try:
                    data = json.loads(line_str)
                    text = data.get("message", {}).get("content", "")
                    if text:
                        emit_event("token", content=text)
                    if data.get("done", False):
                        break
                except Exception:
                    pass
        emit_event("done")
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8", errors="ignore")
        emit_event("error", message=f"Ollama HTTP Error {e.code}")
    except Exception as e:
        emit_event("error", message=f"Ollama Error (Make sure Ollama is running): {str(e)}")

def process_command(raw_input):
    if not raw_input.strip():
        return
    try:
        cmd = json.loads(raw_input)
    except Exception as e:
        emit_event("error", message=f"Invalid JSON input: {str(e)}")
        return

    action = cmd.get("action", "prompt")
    if action == "check_keys":
        check_keys()
        return

    if action == "save_key":
        provider = cmd.get("provider", "").strip().lower()
        key_val = cmd.get("key", "").strip()
        if not provider or not key_val:
            emit_event("error", message="Usage: `/key <gemini|claude|groq> <API_KEY>`")
            return
        saved_file = save_stored_key(provider, key_val)
        check_keys()
        emit_event("token", content=f"✅ API Key for **{provider.upper()}** saved successfully to `{saved_file}`!")
        emit_event("done")
        return

    model = cmd.get("model", "gemini").lower()
    messages = cmd.get("messages", [])
    system_prompt = cmd.get("system_prompt", "You are a helpful AI assistant integrated into a Linux desktop shell control center.")

    if model.startswith("gemini"):
        specific = None
        if "pro" in model:
            specific = "gemini-1.5-pro"
        elif "3.6" in model or "2.5" in model:
            specific = "gemini-2.5-flash"
        stream_gemini(messages, system_prompt, specific_model=specific)
    elif model == "claude":
        stream_claude(messages, system_prompt)
    elif model == "groq":
        stream_groq(messages, system_prompt)
    elif model == "ollama":
        stream_ollama(messages, system_prompt)
    else:
        emit_event("error", message=f"Unknown model: '{model}'. Supported: gemini, claude, groq, ollama")

def main():
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if arg == "--check-keys":
            check_keys()
        else:
            process_command(arg)
        return

    for line in sys.stdin:
        process_command(line)

if __name__ == "__main__":
    main()
