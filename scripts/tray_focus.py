#!/usr/bin/env python3
"""
Quickshell System Tray Focus & Window Manager Helper
Handles showing/hiding background applications (Electron, GTK, Qt) on Hyprland.

Uses a Hyprland SPECIAL workspace (not a numbered off-screen one) for hiding.
Special workspaces are the compositor-native "scratchpad" primitive and are
the reliable way to toggle window visibility without breaking Electron's
Wayland frame-callback/compositor-commit expectations.

All moves/focuses go through plain `hyprctl dispatch <dispatcher> ...`
(the stable, core-C++ dispatcher path) rather than the newer hl.dsp Lua
scripting API, which has known edge cases around window state transitions.

NEVER kills or terminates any background process.
"""
import json
import sys
import os
import re
import subprocess
import time

LOG_FILE = "/tmp/tray_focus_debug.log"
HIDDEN_SPECIAL = "special:trayhidden"  # single shared scratchpad workspace for all tray apps


def log(msg):
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"[{time.strftime('%H:%M:%S.%f')[:-3]}] {msg}\n")
    except Exception:
        pass


item_id = sys.argv[1] if len(sys.argv) > 1 else ""
item_title = sys.argv[2] if len(sys.argv) > 2 else ""
item_icon = sys.argv[3] if len(sys.argv) > 3 else ""

log("--- TRAY FOCUS TRIGGERED ---")
log(f"Args -> ID: '{item_id}' | Title: '{item_title}' | Icon: '{item_icon}'")


def hypr_dispatch(*args):
    """Run a single native hyprctl dispatch call. args are passed as-is to `hyprctl dispatch`."""
    try:
        cmd = ["hyprctl", "dispatch"] + list(args)
        log(f"dispatch: {' '.join(cmd)}")
        res = subprocess.run(cmd, capture_output=True, text=True)
        log(f"   -> rc={res.returncode} stdout={res.stdout.strip()} stderr={res.stderr.strip()}")
        return res.returncode == 0
    except Exception as e:
        log(f"dispatch error: {e}")
        return False


def hypr_batch(*dispatch_calls):
    """
    Run multiple dispatchers as a single hyprctl --batch call so they land in
    the same compositor tick. This matters for Electron: move+focus done as
    two separate round trips can race with the surface's next configure/commit.
    Each item in dispatch_calls is a full 'dispatcher args' string.
    """
    try:
        batch_str = " ; ".join(f"dispatch {c}" for c in dispatch_calls)
        cmd = ["hyprctl", "--batch", batch_str]
        log(f"batch: {batch_str}")
        res = subprocess.run(cmd, capture_output=True, text=True)
        log(f"   -> rc={res.returncode} stdout={res.stdout.strip()} stderr={res.stderr.strip()}")
        return res.returncode == 0
    except Exception as e:
        log(f"batch error: {e}")
        return False


# Mapping of known tray item identifiers to binary launch names
binary_overrides = {
    "motrix": "motrix-next",
    "element": "element-desktop",
    "matrix": "element-desktop",
    "discord": "discord",
    "vesktop": "vesktop",
    "webcord": "webcord",
    "telegram": "telegram-desktop",
    "steam": "steam",
    "spotify": "spotify",
    "slack": "slack",
    "obsidian": "obsidian",
    "signal": "signal-desktop",
    "youtube-music": "pear-desktop",
    "com.github.th-ch.youtube-music": "pear-desktop",
    "pear": "pear-desktop",
    "1password": "1password",
    "nextcloud": "nextcloud",
    "dropbox": "dropbox",
    "pavucontrol": "pavucontrol",
    "gammastep": "gammastep-indicator",
}

aliases = {
    "motrix": ["motrix", "motrix-next", "net.agalwood.motrix"],
    "element": ["element", "element-desktop", "io.element.element"],
    "discord": ["discord", "vesktop", "webcord", "discord-canary", "discord-ptb"],
    "vesktop": ["vesktop", "discord"],
    "webcord": ["webcord", "discord"],
    "telegram": ["telegram", "telegram-desktop", "org.telegram.desktop"],
    "steam": ["steam", "com.valvesoftware.steam"],
    "spotify": ["spotify", "com.spotify.client"],
    "slack": ["slack", "com.slack.slack"],
    "obsidian": ["obsidian", "md.obsidian.obsidian"],
    "signal": ["signal", "signal-desktop", "org.signal.signal"],
    "youtube-music": ["youtube-music", "com.github.th-ch.youtube-music", "pear", "pear-desktop", "youtube"],
    "gammastep": ["gammastep", "gammastep-indicator"],
}

binary_name = ""
for k, v in binary_overrides.items():
    if k in item_id.lower() or k in item_title.lower() or k in item_icon.lower():
        binary_name = v
        break

search_terms = []
if binary_name:
    search_terms.append(binary_name.lower())

for s in [item_id, item_title, item_icon]:
    if s and not s.startswith("org.kde.StatusNotifierItem") and not s.startswith("sni_") and not s.startswith("image://"):
        search_terms.append(s.lower())

for s in list(search_terms):
    for key, vals in aliases.items():
        if key in s:
            search_terms.extend([v.lower() for v in vals])

clean_terms = []
for term in search_terms:
    term_clean = re.sub(r'_status_icon_\d+$', '', term.lower())
    base = term_clean.split("/")[-1].split(".")[-1]
    if base and len(base) > 2 and base not in clean_terms and base not in ["statusnotifieritem", "sni", "org", "kde", "desktop", "image"]:
        clean_terms.append(base.lower())
    if term_clean and len(term_clean) > 2 and term_clean not in clean_terms and term_clean not in ["statusnotifieritem", "sni", "org", "kde", "desktop", "image"]:
        clean_terms.append(term_clean.lower())

log(f"Matching terms: {clean_terms}")


def get_matching_pids(terms):
    our_pid = os.getpid()
    pids = set()
    for term in terms:
        if term and len(term) > 2 and term not in ["statusnotifieritem", "sni", "org", "kde", "desktop"]:
            try:
                out = subprocess.check_output(["pgrep", "-f", term]).decode("utf-8").strip().split()
                for p in out:
                    if p.isdigit():
                        pid = int(p)
                        if pid != our_pid:
                            pids.add(pid)
            except Exception:
                pass
    return pids


def get_hyprland_clients():
    try:
        clients_raw = subprocess.check_output(["hyprctl", "clients", "-j"]).decode("utf-8")
        return json.loads(clients_raw)
    except Exception as e:
        log(f"Error fetching Hyprland clients: {e}")
        return []


def find_matching_window(terms, pids):
    clients = get_hyprland_clients()

    if pids:
        for c in clients:
            c_pid = c.get("pid")
            if c_pid in pids:
                log(f"Matched window via PID {c_pid}: address={c.get('address')}, class={c.get('class')}")
                return c

    for c in clients:
        c_class = str(c.get("class", "")).lower()
        c_title = str(c.get("title", "")).lower()
        c_initial = str(c.get("initialClass", "")).lower()

        for term in terms:
            if term and len(term) > 2 and (term in c_class or term in c_title or term in c_initial or c_class in term):
                log(f"Matched window via term '{term}': address={c.get('address')}, class={c.get('class')}, title={c_title}")
                return c

    return None


def trigger_dbus_activate():
    try:
        reg_out = subprocess.check_output(
            ["busctl", "--user", "get-property", "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher",
             "org.kde.StatusNotifierWatcher", "RegisteredStatusNotifierItems"],
            stderr=subprocess.DEVNULL
        ).decode("utf-8", errors="ignore")

        items = re.findall(r"\"([^\"]+)\"", reg_out)
        for item in items:
            parts = item.split("/", 1)
            srv = parts[0]
            pth = "/" + parts[1] if len(parts) > 1 else "/StatusNotifierItem"
            try:
                bus_id = subprocess.check_output(
                    ["busctl", "--user", "get-property", srv, pth, "org.kde.StatusNotifierItem", "Id"],
                    stderr=subprocess.DEVNULL
                ).decode("utf-8", errors="ignore").strip().lower()

                if any(term and term in bus_id for term in clean_terms):
                    log(f"Sending DBus Activate(0, 0) to service '{srv}' ({pth})...")
                    subprocess.run(["busctl", "--user", "call", srv, pth, "org.kde.StatusNotifierItem", "Activate",
                                     "ii", "0", "0"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception:
                pass
    except Exception as e:
        log(f"DBus Activate trigger notice: {e}")


# 1. Fetch current active window & workspace
active_win_addr = ""
curr_ws = "1"
try:
    active_data = json.loads(subprocess.check_output(["hyprctl", "activewindow", "-j"]).decode("utf-8"))
    active_win_addr = active_data.get("address", "")
except Exception:
    pass

try:
    ws_json = json.loads(subprocess.check_output(["hyprctl", "activeworkspace", "-j"]).decode("utf-8"))
    ws_name = str(ws_json.get("name") or ws_json.get("id") or "1")
    if not ws_name.startswith("special"):
        curr_ws = ws_name
except Exception:
    pass

log(f"Current active visible workspace: {curr_ws} | Active window addr: '{active_win_addr}'")

matching_pids = get_matching_pids(clean_terms)
target_win = find_matching_window(clean_terms, matching_pids)


def show_window(addr):
    """Bring a window from anywhere (special workspace or elsewhere) to the
    current workspace, on top, and focused — as a single atomic batch."""
    hypr_batch(
        f'movetoworkspacesilent {curr_ws},address:{addr}',
        f'focuswindow address:{addr}',
        f'alterzorder top,address:{addr}',
    )


def hide_window(addr):
    """Move a window into the shared special (scratchpad) workspace.
    This is the compositor-native hide primitive — unlike a numbered
    off-screen workspace, special workspaces are explicitly designed to
    be safely re-shown later without surface/render state getting stuck."""
    hypr_batch(f'movetoworkspacesilent {HIDDEN_SPECIAL},address:{addr}')
    # keep the user's focus on whatever workspace they were already on
    hypr_dispatch(f'workspace {curr_ws}')


if target_win:
    target_addr = target_win.get("address", "")
    target_ws_name = str(target_win.get("workspace", {}).get("name", ""))

    is_visible_and_active = (
        active_win_addr == target_addr
        and target_ws_name == curr_ws
        and not target_ws_name.startswith("special")
    )

    if is_visible_and_active:
        log(f"Target window {target_addr} is visible & active. Hiding to {HIDDEN_SPECIAL}...")
        hide_window(target_addr)
        sys.exit(0)
    else:
        log(f"Found target window {target_addr} on workspace '{target_ws_name}'. Showing on {curr_ws}...")
        show_window(target_addr)
        sys.exit(0)

# 2. No mapped window found — try DBus activate then poll for it to map
log("No mapped window surface found initially. Triggering DBus activate and polling Hyprland clients...")
trigger_dbus_activate()

for attempt in range(10):
    time.sleep(0.15)
    matching_pids = get_matching_pids(clean_terms)
    target_win = find_matching_window(clean_terms, matching_pids)
    if target_win:
        target_addr = target_win.get("address", "")
        log(f"Window mapped on attempt {attempt + 1}! Showing {target_addr} on {curr_ws}...")
        show_window(target_addr)
        sys.exit(0)

# 3. Still nothing mapped — launch the binary directly (no killing anything)
cmd_to_run = binary_name if binary_name else (clean_terms[0] if clean_terms else "")
if cmd_to_run:
    log(f"No window mapped after polling. Launching: '{cmd_to_run}'")
    try:
        subprocess.Popen(
            [cmd_to_run],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except Exception as e:
        log(f"Launch failed via Popen, falling back to hyprctl dispatch exec: {e}")
        hypr_dispatch(f'exec {cmd_to_run}')
else:
    log("No executable name found to launch.")