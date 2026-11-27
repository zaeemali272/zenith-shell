#!/usr/bin/env python3
import json
import os
import re
import shutil
import subprocess
import sys


def clean_file_path(p):
    if not p or not isinstance(p, str):
        return ""
    p = p.strip()
    if p.startswith("file://"):
        p = p[7:]
    return os.path.expanduser(p)


def find_media_file(data):
    """
    Extracts potential media file and type ('screenshot' | 'recording') from notification payload.
    """
    app_name = (data.get("appName") or "").lower()
    summary = str(data.get("summary") or "")
    body = str(data.get("body") or "")
    image = clean_file_path(data.get("image") or "")
    icon = clean_file_path(data.get("icon") or "")
    hints = data.get("hints") or {}

    sync_hint = str(hints.get("x-canonical-private-synchronous") or "").lower()
    cat_hint = str(hints.get("category") or "").lower()

    combined_text = f"{app_name} {summary} {body} {image} {icon} {sync_hint} {cat_hint}".lower()

    is_screenshot = (
        any(k in combined_text for k in ["screenshot", "snip", "hyprshot", "grimblast", "grim", "flameshot", "spectacle"])
        or ".png" in combined_text
        or ".jpg" in combined_text
        or ".jpeg" in combined_text
        or sync_hint == "screenshot"
    )
    is_recording = (
        any(k in combined_text for k in ["recorder", "recording", "screenrec", "wf-recorder", "gpu-screen-recorder", "screen record"])
        or ".mp4" in combined_text
        or ".mkv" in combined_text
        or ".webm" in combined_text
        or sync_hint == "record"
    )

    if not (is_screenshot or is_recording):
        return None, None

    # 1. Direct path check from image or icon
    for candidate in [image, icon]:
        if candidate and os.path.isfile(candidate):
            ext = os.path.splitext(candidate)[1].lower()
            if ext in [".png", ".jpg", ".jpeg", ".webp", ".bmp", ".mp4", ".mkv", ".webm", ".mov", ".gif"]:
                media_type = "recording" if ext in [".mp4", ".mkv", ".webm", ".mov"] else "screenshot"
                return candidate, media_type

    # 2. Extract full path from body or summary
    text_to_search = f"{summary}\n{body}"
    path_matches = re.findall(
        r'/(?:[a-zA-Z0-9_\.\-]+/)+[a-zA-Z0-9_\.\-]+\.(?:png|jpg|jpeg|webp|mp4|mkv|webm|mov|gif)',
        text_to_search,
    )
    for p in path_matches:
        if os.path.isfile(p):
            ext = os.path.splitext(p)[1].lower()
            media_type = "recording" if ext in [".mp4", ".mkv", ".webm", ".mov"] else "screenshot"
            return p, media_type

    # 3. Extract filename from body or summary
    file_matches = re.findall(
        r'[a-zA-Z0-9_\.\-]+\.(?:png|jpg|jpeg|webp|mp4|mkv|webm|mov|gif)',
        text_to_search,
    )
    home = os.path.expanduser("~")
    search_dirs = [
        os.path.join(home, "Pictures", "Screenshots"),
        os.path.join(home, "Pictures"),
        os.path.join(home, "Videos", "Recordings"),
        os.path.join(home, "Videos"),
        os.path.join(home, "Downloads"),
        "/tmp",
    ]
    for fn in file_matches:
        for d in search_dirs:
            cand = os.path.join(d, fn)
            if os.path.isfile(cand):
                ext = os.path.splitext(cand)[1].lower()
                media_type = "recording" if ext in [".mp4", ".mkv", ".webm", ".mov"] else "screenshot"
                return cand, media_type

    # 4. Check /tmp/recording-state if recording
    if is_recording and os.path.isfile("/tmp/recording-state"):
        try:
            with open("/tmp/recording-state", "r") as f:
                state_path = f.read().strip()
                if state_path and os.path.isfile(state_path):
                    return state_path, "recording"
        except Exception:
            pass

    # 5. Fallback for recent screenshot/recording in standard directories
    if is_screenshot:
        for d in [os.path.join(home, "Pictures", "Screenshots"), os.path.join(home, "Pictures")]:
            if os.path.isdir(d):
                files = [
                    os.path.join(d, f)
                    for f in os.listdir(d)
                    if f.lower().endswith((".png", ".jpg", ".jpeg", ".webp"))
                ]
                if files:
                    newest = max(files, key=os.path.getmtime)
                    return newest, "screenshot"

    if is_recording:
        for d in [os.path.join(home, "Videos", "Recordings"), os.path.join(home, "Videos")]:
            if os.path.isdir(d):
                files = [
                    os.path.join(d, f)
                    for f in os.listdir(d)
                    if f.lower().endswith((".mp4", ".mkv", ".webm", ".mov"))
                ]
                if files:
                    newest = max(files, key=os.path.getmtime)
                    return newest, "recording"

    return None, None


def handle_media(media_file):
    """
    Opens both the photo/video file and its containing directory.
    """
    if not media_file or not os.path.isfile(media_file):
        return False

    media_dir = os.path.dirname(os.path.abspath(media_file))

    # 1. Open the photo or video
    try:
        subprocess.Popen(
            ["xdg-open", media_file],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception as e:
        print(f"Failed to open media file {media_file}: {e}", file=sys.stderr)

    # 2. Open the containing folder
    try:
        if shutil.which("thunar"):
            subprocess.Popen(
                ["thunar", media_dir],
                start_new_session=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        else:
            subprocess.Popen(
                ["xdg-open", media_dir],
                start_new_session=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
    except Exception as e:
        print(f"Failed to open media directory {media_dir}: {e}", file=sys.stderr)

    return True


def handle_window(data):
    """
    Finds the corresponding Hyprland client/window and redirects/focuses it across workspaces.
    """
    app_name = (data.get("appName") or "").strip()
    desktop_entry = (data.get("desktopEntry") or "").strip()
    summary = (data.get("summary") or "").strip()
    body = (data.get("body") or "").strip()
    pid = data.get("pid") or 0
    try:
        pid = int(pid)
    except Exception:
        pid = 0

    # Retrieve Hyprland clients
    try:
        res = subprocess.run(
            ["hyprctl", "clients", "-j"],
            capture_output=True,
            text=True,
            timeout=2,
        )
        if res.returncode != 0:
            clients = []
        else:
            clients = json.loads(res.stdout)
    except Exception as e:
        print(f"Failed to fetch hyprctl clients: {e}", file=sys.stderr)
        clients = []

    if clients:
        app_norm = app_name.lower().replace(" ", "").replace("-", "")
        entry_norm = (
            desktop_entry.lower()
            .replace("org.", "")
            .replace("com.", "")
            .replace(".desktop", "")
            .replace("-", "")
            .replace("_", "")
        )

        best_client = None
        best_score = 0

        for c in clients:
            c_class = (c.get("class") or "").lower()
            c_init = (c.get("initialClass") or "").lower()
            c_title = (c.get("title") or "").lower()
            c_pid = c.get("pid") or 0

            c_class_norm = c_class.replace("-", "").replace("_", "")
            c_init_norm = c_init.replace("-", "").replace("_", "")

            score = 0
            if pid > 0 and c_pid == pid:
                score = 100
            elif entry_norm and (
                entry_norm == c_class_norm
                or entry_norm == c_init_norm
                or entry_norm in c_class_norm
                or c_class_norm in entry_norm
            ):
                score = 90
            elif app_norm and (
                app_norm in c_class_norm
                or c_class_norm in app_norm
                or app_norm in c_init_norm
                or c_init_norm in app_norm
            ):
                score = 80
            elif summary and (summary.lower() in c_title or c_title in summary.lower()):
                score = 75
            elif app_name and app_name.lower() in c_title:
                score = 70
            elif entry_norm and entry_norm in c_title:
                score = 60

            if score > best_score:
                best_score = score
                best_client = c

        if best_client and best_score >= 60:
            address = best_client.get("address")
            ws = best_client.get("workspace", {})
            ws_name = str(ws.get("name") or "")

            # If on special workspace, toggle it first
            if ws_name.startswith("special:"):
                spec_name = ws_name.replace("special:", "")
                subprocess.run(
                    ["hyprctl", "dispatch", f"togglespecialworkspace {spec_name}"],
                    capture_output=True,
                    timeout=2,
                )

            # Focus window via Lua dispatch in Hyprland
            lua_focus = f'''for _, w in ipairs(hl.get_windows()) do
                if tostring(w.address) == "{address}" then
                    hl.dispatch(hl.dsp.focus({{ window = w }}))
                    break
                end
            end'''
            res = subprocess.run(
                ["hyprctl", "eval", lua_focus],
                capture_output=True,
                text=True,
                timeout=2,
            )
            if res.returncode == 0 and "ok" in res.stdout:
                return True

            # Fallback to standard dispatch
            res2 = subprocess.run(
                ["hyprctl", "dispatch", "focuswindow", f"address:{address}"],
                capture_output=True,
                timeout=2,
            )
            if res2.returncode == 0:
                return True

    # If no window found, check for URL in summary or body
    urls = re.findall(r'https?://[^\s<>"]+', f"{summary} {body}")
    if urls:
        subprocess.Popen(
            ["xdg-open", urls[0]],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True

    # If desktopEntry available and no window was open, launch app
    if desktop_entry and shutil.which("gtk-launch"):
        subprocess.Popen(
            ["gtk-launch", desktop_entry],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True

    return False


def main():
    if len(sys.argv) < 2:
        return

    try:
        data = json.loads(sys.argv[1])
    except Exception:
        return

    # Check for screenshot or recording media
    media_file, media_type = find_media_file(data)
    if media_file:
        handle_media(media_file)
        return

    # Redirect to corresponding app window / tab
    handle_window(data)


if __name__ == "__main__":
    main()
