#!/usr/bin/env python3
import json
import sys
import os
import re
import subprocess
import time

LOG_FILE = "/tmp/tray_focus_debug.log"

def log(msg):
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"[{time.strftime('%H:%M:%S.%f')[:-3]}] {msg}\n")
    except Exception:
        pass

item_id = sys.argv[1] if len(sys.argv) > 1 else ""
item_title = sys.argv[2] if len(sys.argv) > 2 else ""
item_icon = sys.argv[3] if len(sys.argv) > 3 else ""

log(f"Args -> ID: '{item_id}' | Title: '{item_title}' | Icon: '{item_icon}'")

def hypr_dispatch_lua(lua_cmd):
    try:
        log(f"Executing Hyprland Lua Dispatcher: hyprctl dispatch '{lua_cmd}'")
        res = subprocess.run(["hyprctl", "dispatch", lua_cmd], capture_output=True, text=True)
        log(f"   Result: returncode={res.returncode}, stdout={res.stdout.strip()}")
    except Exception as e:
        log(f"Hyprctl dispatch error: {e}")

binary_overrides = {
    "motrix": "motrix",
    "element": "element-desktop",
    "matrix": "element-desktop",
    "discord": "discord",
    "vesktop": "vesktop",
    "webcord": "webcord",
    "telegram": "telegram",
    "steam": "steam",
    "spotify": "spotify",
    "slack": "slack",
    "obsidian": "obsidian",
    "signal": "signal",
    "youtube-music": "pear-desktop",
    "com.github.th-ch.youtube-music": "pear-desktop",
    "pear": "pear-desktop"
}

binary_name = ""
for k, v in binary_overrides.items():
    if k in item_id.lower() or k in item_title.lower() or k in item_icon.lower():
        binary_name = v
        break

aliases = {
    "motrix": ["motrix", "net.agalwood.motrix"],
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
    "youtube-music": ["youtube-music", "com.github.th-ch.youtube-music", "pear", "pear-desktop", "youtube"]
}

search_terms = []
if binary_name: search_terms.append(binary_name.lower())
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
    if base and base not in clean_terms: clean_terms.append(base.lower())
    if term_clean not in clean_terms: clean_terms.append(term_clean.lower())

log(f"Final clean_terms for matching: {clean_terms}")

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
            except Exception: pass
    return pids

def find_matching_window(terms, pids):
    try:
        clients_raw = subprocess.check_output(["hyprctl", "clients", "-j"]).decode("utf-8")
        clients = json.loads(clients_raw)
        
        if pids:
            for c in clients:
                c_pid = c.get("pid")
                if c_pid in pids:
                    log(f"Matched window via PID {c_pid}: address={c.get('address')}")
                    return c

        for c in clients:
            c_class = str(c.get("class", "")).lower()
            c_title = str(c.get("title", "")).lower()
            c_initial = str(c.get("initialClass", "")).lower()

            for term in terms:
                if term and len(term) > 2 and (term in c_class or term in c_title or term in c_initial or c_class in term):
                    log(f"Matched window via term '{term}': class={c_class}, title={c_title}")
                    return c
    except Exception as e:
        log(f"Error in find_matching_window: {e}")
    return None

matching_pids = get_matching_pids(clean_terms)
target_win = find_matching_window(clean_terms, matching_pids)

curr_ws = "1"
active_win_addr = ""
try:
    active_data = json.loads(subprocess.check_output(["hyprctl", "activewindow", "-j"]).decode("utf-8"))
    active_win_addr = active_data.get("address", "")
except Exception: pass

try:
    curr_ws = str(json.loads(subprocess.check_output(["hyprctl", "activeworkspace", "-j"]).decode("utf-8")).get("id") or "1")
except Exception: pass

# If window is mapped and currently focused on active workspace -> hide to special:minimized
if target_win and active_win_addr == target_win.get("address") and str(target_win.get("workspace", {}).get("id", "")) == curr_ws:
    addr = target_win.get("address")
    log("Window is currently active and focused. Hiding to special:minimized...")
    hypr_dispatch_lua(f'hl.dsp.window.move({{ window = "{addr}", workspace = "special:minimized" }})')
    sys.exit(0)

# Step 1: Try D-Bus Activation & DBusMenu Triggering
try:
    reg_out = subprocess.check_output(["busctl", "--user", "get-property", "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher", "org.kde.StatusNotifierWatcher", "RegisteredStatusNotifierItems"], stderr=subprocess.STDOUT).decode("utf-8", errors="ignore")
    items = re.findall(r"\"([^\"]+)\"", reg_out)
    for item in items:
        parts = item.split("/", 1)
        srv = parts[0]
        pth = "/" + parts[1] if len(parts) > 1 else "/StatusNotifierItem"
        try:
            bus_id = subprocess.check_output(["busctl", "--user", "get-property", srv, pth, "org.kde.StatusNotifierItem", "Id"], stderr=subprocess.STDOUT).decode("utf-8", errors="ignore").strip().lower()
            match = any(term and term in bus_id for term in clean_terms)
            if match:
                log(f"Found DBus match on service '{srv}' (id '{bus_id}'). Calling Activate & DBusMenu Event...")
                subprocess.run(["busctl", "--user", "call", srv, pth, "org.kde.StatusNotifierItem", "Activate", "ii", "0", "0"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
                try:
                    menu_out = subprocess.check_output(["busctl", "--user", "call", srv, "/com/canonical/dbusmenu", "com.canonical.dbusmenu", "GetLayout", "iias", "0", "1", "0"], stderr=subprocess.STDOUT).decode("utf-8", errors="ignore")
                    menu_items = re.findall(r"\(ia\{sv\}av\)\s+(\d+)\s+\d+\s+\"label\"\s+s\s+\"([^\"]+)\"", menu_out)
                    for item_id_num, label in menu_items:
                        l_lower = label.lower()
                        if any(k in l_lower for k in ["show", "open", "toggle", "display", "restore"]):
                            log(f"Triggering DBusMenu item {item_id_num} ('{label}') on service {srv}...")
                            subprocess.run(["busctl", "--user", "call", srv, "/com/canonical/dbusmenu", "com.canonical.dbusmenu", "Event", "isvu", str(item_id_num), "clicked", "s", "", "0"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                except Exception: pass
        except Exception: pass
except Exception as e:
    log(f"Error in D-Bus activation: {e}")

time.sleep(0.15)
matching_pids = get_matching_pids(clean_terms)
target_win = find_matching_window(clean_terms, matching_pids)

if target_win:
    addr = target_win.get("address")
    log(f"Bringing window {addr} to active workspace {curr_ws} and focusing...")
    hypr_dispatch_lua(f'hl.dsp.window.move({{ window = "{addr}", workspace = "{curr_ws}" }})')
    hypr_dispatch_lua(f'hl.dsp.focus({{ workspace = "{curr_ws}" }})')
else:
    log("No window mapped. Launching binary via Hyprland exec_cmd...")
    cmd_to_run = binary_name if binary_name else (clean_terms[0] if clean_terms else "")
    if cmd_to_run:
        hypr_dispatch_lua(f'hl.dsp.exec_cmd("{cmd_to_run}")')