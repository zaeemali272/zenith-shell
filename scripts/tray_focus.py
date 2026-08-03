#!/usr/bin/env python3
import json
import sys
import os
import re
import subprocess
import socket
import time

item_id = sys.argv[1] if len(sys.argv) > 1 else ""
item_title = sys.argv[2] if len(sys.argv) > 2 else ""
item_icon = sys.argv[3] if len(sys.argv) > 3 else ""

def hypr_dispatch_cmd(cmd_type, *args):
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig: return
    sock_path = f"/run/user/{os.getuid()}/hypr/{sig}/.socket.sock"
    if not os.path.exists(sock_path):
        sock_path = f"/tmp/hypr/{sig}/.socket.sock"
    if not os.path.exists(sock_path): return

    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(sock_path)

        if cmd_type == "exec":
            cmd = args[0]
            # Hyprland 0.56+ Lua dispatch
            lua_cmd = f"dispatch hl.dsp.exec_cmd(\"{cmd}\")"
            s.sendall(lua_cmd.encode("utf-8"))
            res = s.recv(1024).decode("utf-8", errors="ignore")
            if "error" in res.lower() or "unknown" in res.lower():
                subprocess.Popen([cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)

        elif cmd_type == "movetoworkspace":
            ws, addr = args[0], args[1]
            lua_cmd = f"dispatch hl.dsp.window.move({{ workspace = {ws}, window = \"address:{addr}\" }})"
            s.sendall(lua_cmd.encode("utf-8"))
            res = s.recv(1024).decode("utf-8", errors="ignore")
            if "error" in res.lower():
                s2 = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                s2.connect(sock_path)
                s2.sendall(f"dispatch movetoworkspace {ws},address:{addr}".encode("utf-8"))
                s2.close()

        elif cmd_type == "focuswindow":
            addr = args[0]
            lua_cmd = f"dispatch hl.dsp.focus({{ window = \"address:{addr}\" }})"
            s.sendall(lua_cmd.encode("utf-8"))
            res = s.recv(1024).decode("utf-8", errors="ignore")
            if "error" in res.lower():
                s2 = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                s2.connect(sock_path)
                s2.sendall(f"dispatch focuswindow address:{addr}".encode("utf-8"))
                s2.close()

        s.close()
    except Exception: pass

target_pid = None

# Extract PID from SNI item strings if present
for s in [item_id, item_title, item_icon]:
    m = re.search(r'(?:StatusNotifierItem|sni)[_-](\d+)', s, re.IGNORECASE)
    if m:
        val = int(m.group(1))
        if val > 1000:
            target_pid = val
            break

generic_binaries = {"electron", "python", "python3", "bash", "sh", "systemd", "init", "zsh", "fish", "node", "appimage", "bwrap"}

def extract_binary_from_cmdline(pid):
    if not os.path.exists(f"/proc/{pid}/cmdline"):
        return ""
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            parts = f.read().decode("utf-8", errors="ignore").split("\x00")
            for part in parts:
                if not part or part.startswith("-"):
                    continue
                nix_match = re.search(r'/nix/store/[a-z0-9]{32}-([a-zA-Z0-9_\-]+)', part)
                if nix_match:
                    pkg_raw = nix_match.group(1)
                    pkg = re.sub(r'-(?:\d[\d\.]*|unwrapped|wrapped).*', '', pkg_raw).lower()
                    if pkg and pkg not in generic_binaries:
                        return pkg

                base = os.path.basename(part)
                base_clean = re.sub(r'^\.|\.(?:wrapped|unwrapped)$|-(?:wrapped|unwrapped)$', '', base).lower()
                if base_clean and base_clean not in generic_binaries:
                    return base_clean
    except Exception: pass
    return ""

binary_name = ""
if target_pid:
    binary_name = extract_binary_from_cmdline(target_pid)

binary_overrides = {
    "element": "element-desktop",
    "matrix": "element-desktop",
    "pear": "pear-desktop",
    "youtube": "pear-desktop",
    "com.github.th-ch.youtube-music": "pear-desktop",
    "youtube-music": "pear-desktop",
    "discord": "discord",
    "vesktop": "vesktop",
    "webcord": "webcord",
    "telegram": "telegram-desktop",
    "steam": "steam",
    "spotify": "spotify",
    "slack": "slack",
    "obsidian": "obsidian",
    "signal": "signal-desktop"
}

for k, v in binary_overrides.items():
    if k in item_id.lower() or k in item_title.lower() or k in item_icon.lower():
        if not binary_name:
            binary_name = v
            break

aliases = {
    "element": ["element", "element-desktop", "matrix", "io.element.element"],
    "pear": ["com.github.th-ch.youtube-music", "youtube-music", "youtube_music", "pear", "pear-desktop", "youtube"],
    "youtube": ["com.github.th-ch.youtube-music", "youtube-music", "youtube_music", "pear", "pear-desktop", "youtube"],
    "com.github.th-ch.youtube-music": ["com.github.th-ch.youtube-music", "youtube-music", "youtube_music", "pear", "pear-desktop", "youtube"],
    "discord": ["discord", "vesktop", "webcord", "discord-canary", "discord-ptb"],
    "vesktop": ["vesktop", "discord"],
    "webcord": ["webcord", "discord"],
    "telegram": ["telegram", "telegram-desktop", "org.telegram.desktop"],
    "steam": ["steam", "com.valvesoftware.steam"],
    "spotify": ["spotify", "com.spotify.client"],
    "slack": ["slack", "com.slack.slack"],
    "obsidian": ["obsidian", "md.obsidian.obsidian"],
    "signal": ["signal", "signal-desktop", "org.signal.signal"],
    "qpwgraph": ["qpwgraph", "org.rncbc.qpwgraph"]
}

search_terms = []
if binary_name: search_terms.append(binary_name.lower())
for s in [item_id, item_title, item_icon]:
    if s and not s.startswith("org.kde.StatusNotifierItem") and not s.startswith("sni_"):
        search_terms.append(s.lower())

for s in list(search_terms):
    for key, vals in aliases.items():
        if key in s:
            search_terms.extend(vals)

clean_terms = []
for term in search_terms:
    term_clean = re.sub(r'_status_icon_\d+$', '', term)
    base = term_clean.split("/")[-1].split(".")[-1]
    if base and base not in clean_terms: clean_terms.append(base)
    if term_clean not in clean_terms: clean_terms.append(term_clean)

# Build process tree PIDs
tree_pids = set()
if target_pid:
    tree_pids.add(target_pid)

try:
    for pdir in os.listdir("/proc"):
        if pdir.isdigit():
            pid = int(pdir)
            b = extract_binary_from_cmdline(pid)
            if b:
                for term in clean_terms:
                    if term and (term in b or b in term):
                        tree_pids.add(pid)
                        break
except Exception: pass

if tree_pids:
    for pid in list(tree_pids):
        curr = pid
        for _ in range(5):
            try:
                with open(f"/proc/{curr}/stat", "r") as f:
                    ppid = int(f.read().split(")")[1].split()[1])
                    if ppid > 1:
                        tree_pids.add(ppid)
                        curr = ppid
                    else: break
            except Exception: break
        try:
            for pdir in os.listdir("/proc"):
                if pdir.isdigit():
                    cpid = int(pdir)
                    try:
                        with open(f"/proc/{cpid}/stat", "r") as f:
                            ppid = int(f.read().split(")")[1].split()[1])
                            if ppid in tree_pids:
                                tree_pids.add(cpid)
                    except Exception: pass
        except Exception: pass

# Directly trigger D-Bus Activate on matching SNI items
try:
    reg_out = subprocess.check_output(["busctl", "--user", "get-property", "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher", "org.kde.StatusNotifierWatcher", "RegisteredStatusNotifierItems"], stderr=subprocess.DEVNULL).decode("utf-8", errors="ignore")
    dbus_buses = re.findall(r':\d+\.\d+', reg_out)
    for bus in dbus_buses:
        try:
            bus_id = subprocess.check_output(["busctl", "--user", "get-property", bus, "/StatusNotifierItem", "org.kde.StatusNotifierItem", "Id"], stderr=subprocess.DEVNULL).decode("utf-8", errors="ignore").strip().lower()
            match = False
            for term in clean_terms:
                if term and term in bus_id:
                    match = True
                    break
            if match:
                subprocess.Popen(["busctl", "--user", "call", bus, "/StatusNotifierItem", "org.kde.StatusNotifierItem", "Activate", "ii", "0", "0"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception: pass
except Exception: pass

def find_matching_window(clean_terms, tree_pids):
    try:
        clients = json.loads(subprocess.check_output(["hyprctl", "clients", "-j"]).decode("utf-8"))
        for c in clients:
            c_pid = c.get("pid")
            c_class = str(c.get("class", "")).lower()
            c_title = str(c.get("title", "")).lower()
            c_initial = str(c.get("initialClass", "")).lower()

            if tree_pids and c_pid in tree_pids:
                return c

            for term in clean_terms:
                if term and (term in c_class or term in c_title or term in c_initial or c_class in term):
                    return c
    except Exception: pass
    return None

target_win = None

# Phase 1: Check if window is mapped after DBus activation (15 attempts x 100ms = 1.5s)
for attempt in range(15):
    target_win = find_matching_window(clean_terms, tree_pids)
    if target_win: break
    time.sleep(0.1)

# Phase 2 Fallback: Single-Instance Exec Activation for Unmapped Surfaces on NixOS
if not target_win:
    def find_executable(terms):
        desktop_dirs = [
            "/etc/profiles/per-user/" + os.environ.get("USER", "") + "/share/applications",
            "/run/current-system/sw/share/applications",
            os.path.expanduser("~/.nix-profile/share/applications"),
            os.path.expanduser("~/.local/share/applications"),
            "/usr/share/applications"
        ]
        for d in desktop_dirs:
            if os.path.exists(d):
                try:
                    for f in os.listdir(d):
                        if f.endswith(".desktop"):
                            f_lower = f.lower()
                            for term in terms:
                                if term and term in f_lower:
                                    filepath = os.path.join(d, f)
                                    with open(filepath, "r", errors="ignore") as df:
                                        for line in df:
                                            if line.startswith("Exec="):
                                                exec_line = line.split("=", 1)[1].strip()
                                                exec_clean = re.sub(r'%[a-zA-Z]', '', exec_line).strip()
                                                parts = exec_clean.split()
                                                if parts:
                                                    return parts[0]
                except Exception: pass
        for term in terms:
            if term not in ["statusnotifieritem", "sni", "org", "kde", "desktop"]:
                return term
        return ""

    exec_cmd = find_executable([binary_name] + clean_terms)

    if exec_cmd:
        hypr_dispatch_cmd("exec", exec_cmd)

        # Poll hyprctl clients again for newly mapped surface (20 attempts x 100ms = 2.0s)
        for attempt in range(20):
            time.sleep(0.1)
            target_win = find_matching_window(clean_terms, tree_pids)
            if target_win: break

# Focus and bring target window to active workspace
if target_win:
    addr = target_win.get("address")
    curr_ws = 1
    try:
        curr_ws = json.loads(subprocess.check_output(["hyprctl", "activeworkspace", "-j"]).decode("utf-8")).get("id") or 1
    except Exception: pass
    hypr_dispatch_cmd("movetoworkspace", curr_ws, addr)
    hypr_dispatch_cmd("focuswindow", addr)
