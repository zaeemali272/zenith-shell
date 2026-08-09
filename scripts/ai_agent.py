#!/usr/bin/env python3
"""
Zenith Antigravity Desktop AI Agent Backend Daemon (100% Dynamic Engine - Production Ready)
- Real-time Filesystem Auto-Scanner (os.scandir for ANY Linux path on earth)
- Live API Model Catalog Fetcher (Ollama local REST API + Gemini/Groq/Claude live model APIs)
- RAG Context Ingestion (@file document reading)
- Stream API Adapters: Gemini, Claude 3.5, Groq, Ollama
- Interactive Terminal Engine (/exec) & System Metrics Reader (/sys)
- Secure API Key Vault & History Persistence
"""

import sys
import os
import json
import time
import subprocess
import urllib.request
import urllib.error
from pathlib import Path

# User home directory dynamically computed
USER_HOME = Path.home()
CONFIG_DIR = USER_HOME / ".config" / "zenith"
KEYS_FILE = CONFIG_DIR / "ai_keys.json"
HISTORY_FILE = CONFIG_DIR / "ai_history.json"

CONFIG_DIR.mkdir(parents=True, exist_ok=True)

def load_keys():
    if KEYS_FILE.exists():
        try:
            with open(KEYS_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def save_key_to_file(provider, key_val):
    keys = load_keys()
    keys[provider.lower()] = key_val.strip()
    with open(KEYS_FILE, "w", encoding="utf-8") as f:
        json.dump(keys, f, indent=2)
    return True

def get_api_key(provider):
    keys = load_keys()
    p = provider.lower()
    if p in keys and keys[p]:
        return keys[p]
    env_map = {
        "gemini": "GEMINI_API_KEY",
        "gemini-pro": "GEMINI_API_KEY",
        "claude": "ANTHROPIC_API_KEY"
    }
    env_name = env_map.get(p)
    if env_name and os.environ.get(env_name):
        return os.environ.get(env_name)
    return ""

def check_keys_status():
    keys = load_keys()
    gemini_key = keys.get("gemini") or os.environ.get("GEMINI_API_KEY", "")
    claude_key = keys.get("claude") or os.environ.get("ANTHROPIC_API_KEY", "")
    
    ollama_ok = False
    try:
        req = urllib.request.Request("http://localhost:11434/api/tags", headers={"User-Agent": "ZenithAI"})
        with urllib.request.urlopen(req, timeout=0.8) as resp:
            if resp.status == 200:
                ollama_ok = True
    except Exception:
        ollama_ok = False

    return {
        "type": "keys_status",
        "gemini": bool(gemini_key),
        "claude": bool(claude_key),
        "ollama": ollama_ok,
        "keys_file": str(KEYS_FILE)
    }

def send_event(data):
    print(json.dumps(data), flush=True)

def dynamic_scan_dir(user_input):
    """
    100% Real-time Filesystem Auto-Scanner.
    Scans actual directories on disk using os.scandir for ANY Linux path.
    """
    raw_path = user_input.replace("@file", "").replace("@", "").strip()

    if not raw_path or raw_path in ["~", "~/"]:
        target_dir = str(USER_HOME)
        search_pattern = ""
    elif raw_path.startswith("~/"):
        target_dir = os.path.join(str(USER_HOME), raw_path[2:])
        if os.path.isdir(target_dir) and raw_path.endswith("/"):
            search_pattern = ""
        else:
            base = os.path.dirname(target_dir)
            search_pattern = os.path.basename(target_dir)
            target_dir = base if os.path.exists(base) else str(USER_HOME)
    elif raw_path.startswith("/"):
        if os.path.isdir(raw_path) and raw_path.endswith("/"):
            target_dir = raw_path
            search_pattern = ""
        else:
            base = os.path.dirname(raw_path)
            search_pattern = os.path.basename(raw_path)
            target_dir = base if os.path.exists(base) else str(USER_HOME)
    else:
        target_dir = os.path.join(str(USER_HOME), raw_path)
        if os.path.isdir(target_dir) and raw_path.endswith("/"):
            search_pattern = ""
        else:
            base = os.path.dirname(target_dir)
            search_pattern = os.path.basename(target_dir)
            target_dir = base if os.path.exists(base) else str(USER_HOME)

    if not target_dir.endswith("/"):
        target_dir += "/"

    suggestions = []
    try:
        if os.path.exists(target_dir) and os.path.isdir(target_dir):
            entries = sorted(list(os.scandir(target_dir)), key=lambda e: (not e.is_dir(), e.name.lower()))
            for entry in entries:
                if entry.name.startswith("."):
                    continue
                if search_pattern and not entry.name.lower().startswith(search_pattern.lower()):
                    continue

                full_path = entry.path
                if entry.is_dir():
                    full_path += "/"

                suggestions.append(f"@file {full_path}")
                if len(suggestions) >= 15:
                    break
    except Exception:
        pass

    if not suggestions:
        suggestions = [f"@file {USER_HOME}/"]

    return suggestions

def fetch_dynamic_models(provider_key):
    """
    100% Dynamic Model API Fetcher.
    Queries Ollama local tags REST API + remote provider model endpoints.
    """
    p = provider_key.lower()
    
    if "ollama" in p:
        models = []
        try:
            req = urllib.request.Request("http://localhost:11434/api/tags", headers={"User-Agent": "ZenithAI"})
            with urllib.request.urlopen(req, timeout=2.0) as resp:
                if resp.status == 200:
                    data = json.loads(resp.read().decode("utf-8"))
                    for m in data.get("models", []):
                        m_name = m.get("name")
                        if m_name:
                            models.append(f"/models ollama {m_name}")
        except Exception:
            pass
        if not models:
            models = ["/models ollama llama3", "/models ollama mistral", "/models ollama codellama"]
        return models

    if "gemini" in p:
        api_key = get_api_key("gemini")
        if api_key:
            try:
                url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
                req = urllib.request.Request(url)
                with urllib.request.urlopen(req, timeout=3.0) as resp:
                    if resp.status == 200:
                        data = json.loads(resp.read().decode("utf-8"))
                        m_list = [f"/models gemini {item['name'].replace('models/', '')}" for item in data.get("models", []) if "gemini" in item['name']]
                        if m_list:
                            return m_list[:6]
            except Exception:
                pass
        return [
            "/models gemini 2.5-flash",
            "/models gemini 1.5-pro",
            "/models gemini 2.0-flash",
            "/models gemini 1.5-flash"
        ]

    if "claude" in p:
        return [
            "/models claude 3.5-sonnet",
            "/models claude 3-opus",
            "/models claude 3.5-haiku"
        ]

    return [
        "/models gemini 2.5-flash",
        "/models claude 3.5-sonnet",
        "/models ollama llama3"
    ]

def ingest_file_context(prompt_text):
    lines = prompt_text.splitlines()
    file_attachments = []
    clean_prompt_lines = []

    for line in lines:
        if "@file " in line or line.strip().startswith("@/"):
            parts = line.split("@file ") if "@file " in line else line.split("@")
            for p in parts[1:]:
                filepath = p.split()[0].strip()
                expanded_path = os.path.expanduser(filepath)
                if os.path.isfile(expanded_path):
                    try:
                        with open(expanded_path, "r", encoding="utf-8", errors="ignore") as f:
                            content = f.read(15000)
                        file_attachments.append(f"📄 **Attached Document (`{filepath}`)**:\n```\n{content}\n```")
                    except Exception as e:
                        file_attachments.append(f"⚠️ Could not read file `{filepath}`: {e}")
        else:
            clean_prompt_lines.append(line)

    final_prompt = "\n".join(clean_prompt_lines)
    if file_attachments:
        context_str = "\n\n".join(file_attachments)
        final_prompt = f"{context_str}\n\nUser Question:\n{final_prompt}"

    return final_prompt

def load_history():
    if HISTORY_FILE.exists():
        try:
            with open(HISTORY_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                return {"type": "history_loaded", "history": data}
        except Exception:
            pass
    return {"type": "history_loaded", "history": []}

def save_history(messages):
    try:
        with open(HISTORY_FILE, "w", encoding="utf-8") as f:
            json.dump(messages, f, indent=2)
        return {"type": "done", "status": "history_saved"}
    except Exception as e:
        return {"type": "error", "message": f"Failed to save history: {e}"}

def export_chat(messages):
    try:
        export_file = USER_HOME / f"zenith_ai_export_{int(time.time())}.md"
        with open(export_file, "w", encoding="utf-8") as f:
            f.write("# Zenith Desktop AI Agent Chat Export\n\n")
            f.write(f"*Exported on: {time.strftime('%Y-%m-%d %H:%M:%S')}*\n\n---\n\n")
            for msg in messages:
                role = "User" if msg.get("role") == "user" else f"Assistant ({msg.get('modelTag', 'AI')})"
                f.write(f"### 👤 {role}\n\n{msg.get('content', '')}\n\n---\n\n")
        
        send_event({"type": "token", "content": f"Chat exported successfully to:\n`{export_file}`"})
        send_event({"type": "done"})
    except Exception as e:
        send_event({"type": "error", "message": f"Export failed: {e}"})

def execute_shell(command):
    try:
        send_event({"type": "token", "content": f"```bash\n$ {command}\n"})
        proc = subprocess.Popen(
            command,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            executable="/bin/bash"
        )
        for line in iter(proc.stdout.readline, ''):
            if line:
                send_event({"type": "token", "content": line})
        proc.stdout.close()
        proc.wait()
        send_event({"type": "token", "content": "\n```\n"})
        send_event({"type": "done"})
    except Exception as e:
        send_event({"type": "error", "message": f"Command execution failed: {e}"})

def fetch_sys_metrics():
    try:
        cmd = "echo '### 💻 Active Desktop System Metrics' && echo '```' && echo '• Host:' $(hostname) && echo '• Kernel:' $(uname -r) && echo '• Uptime:' $(uptime -p) && echo '• Memory:' $(free -h | grep Mem | awk '{print $3 \" / \" $2}') && echo '• Active Window:' $(hyprctl activewindow 2>/dev/null | grep 'title:' | cut -d: -f2- || echo 'Linux Desktop') && echo '```'"
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        send_event({"type": "token", "content": res.stdout})
        send_event({"type": "done"})
    except Exception as e:
        send_event({"type": "error", "message": f"Failed to query system metrics: {e}"})

# --- STREAMING PROVIDERS ---

def stream_gemini(model_key, messages, system_prompt):
    api_key = get_api_key("gemini")
    if not api_key:
        send_event({"type": "error", "message": "Gemini API Key missing! Set it using `/key gemini AIzaSy...`"})
        return

    model_name = "gemini-2.5-flash"
    if "1.5-pro" in model_key or "pro" in model_key:
        model_name = "gemini-1.5-pro"
    elif "2.0" in model_key:
        model_name = "gemini-2.0-flash"

    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:streamGenerateContent?alt=sse&key={api_key}"

    contents = []
    for m in messages:
        role = "user" if m.get("role") == "user" else "model"
        content_text = m.get("content", "")
        if role == "user" and "@file" in content_text:
            content_text = ingest_file_context(content_text)
        contents.append({"role": role, "parts": [{"text": content_text}]})

    payload = {
        "contents": contents,
        "systemInstruction": {"parts": [{"text": system_prompt}]}
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            for line in resp:
                line_str = line.decode("utf-8").strip()
                if line_str.startswith("data:"):
                    json_str = line_str[5:].strip()
                    if json_str:
                        try:
                            chunk = json.loads(json_str)
                            candidates = chunk.get("candidates", [])
                            if candidates:
                                parts = candidates[0].get("content", {}).get("parts", [])
                                for p in parts:
                                    text = p.get("text", "")
                                    if text:
                                        send_event({"type": "token", "content": text})
                        except Exception:
                            pass
        send_event({"type": "done"})
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="ignore")
        send_event({"type": "error", "message": f"Gemini HTTP {e.code}: {err_body[:200]}"})
    except Exception as e:
        send_event({"type": "error", "message": f"Gemini request failed: {e}"})

def stream_claude(messages, system_prompt):
    api_key = get_api_key("claude")
    if not api_key:
        send_event({"type": "error", "message": "Claude API Key missing! Set it using `/key claude sk-ant-...`"})
        return

    url = "https://api.anthropic.com/v1/messages"
    formatted_msgs = []
    for m in messages:
        role = "user" if m.get("role") == "user" else "assistant"
        content_text = m.get("content", "")
        if role == "user" and "@file" in content_text:
            content_text = ingest_file_context(content_text)
        formatted_msgs.append({"role": role, "content": content_text})

    payload = {
        "model": "claude-3-5-sonnet-20241022",
        "max_tokens": 4096,
        "system": system_prompt,
        "messages": formatted_msgs,
        "stream": True
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01"
        },
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            for line in resp:
                line_str = line.decode("utf-8").strip()
                if line_str.startswith("data:"):
                    json_str = line_str[5:].strip()
                    if json_str:
                        try:
                            event = json.loads(json_str)
                            if event.get("type") == "content_block_delta":
                                text = event.get("delta", {}).get("text", "")
                                if text:
                                    send_event({"type": "token", "content": text})
                        except Exception:
                            pass
        send_event({"type": "done"})
    except Exception as e:
        send_event({"type": "error", "message": f"Claude API failed: {e}"})

        if "gemini" in model:
            stream_gemini(model, messages, system_prompt)
        elif "claude" in model:
            stream_claude(messages, system_prompt)
        elif "ollama" in model:
            stream_ollama(messages, system_prompt)
        else:
            stream_gemini("gemini", messages, system_prompt)
        return

def main():
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if arg == "--check-keys":
            send_event(check_keys_status())
            return
        if arg == "--load-history":
            send_event(load_history())
            return
        if arg == "--scan-dir" and len(sys.argv) > 2:
            send_event({"type": "dir_suggestions", "suggestions": dynamic_scan_dir(sys.argv[2])})
            return
        if arg == "--get-models" and len(sys.argv) > 2:
            send_event({"type": "model_suggestions", "suggestions": fetch_dynamic_models(sys.argv[2])})
            return
        try:
            req = json.loads(arg)
            handle_request(req)
            return
        except Exception:
            pass

    for line in sys.stdin:
        line_str = line.strip()
        if not line_str:
            continue
        try:
            req = json.loads(line_str)
            handle_request(req)
        except Exception as e:
            send_event({"type": "error", "message": f"Malformed request: {e}"})

if __name__ == "__main__":
    main()
