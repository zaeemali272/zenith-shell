#!/usr/bin/env bash

python3 -c '
import json, os, glob, time, subprocess

def get_stats():
    prev_stat_file = "/tmp/zenith_proc_stat.json"
    prev_stat = {}
    if os.path.exists(prev_stat_file):
        try:
            with open(prev_stat_file, "r") as f:
                prev_stat = json.load(f)
        except Exception:
            pass

    curr_stat = {}
    with open("/proc/stat", "r") as f:
        for line in f:
            if line.startswith("cpu"):
                parts = line.split()
                name = parts[0]
                vals = [int(x) for x in parts[1:]]
                idle = vals[3] + (vals[4] if len(vals) > 4 else 0)
                total = sum(vals)
                curr_stat[name] = {"idle": idle, "total": total}

    try:
        with open(prev_stat_file, "w") as f:
            json.dump(curr_stat, f)
    except Exception:
        pass

    if not prev_stat:
        time.sleep(0.1)
        with open("/proc/stat", "r") as f:
            for line in f:
                if line.startswith("cpu"):
                    parts = line.split()
                    name = parts[0]
                    vals = [int(x) for x in parts[1:]]
                    idle = vals[3] + (vals[4] if len(vals) > 4 else 0)
                    total = sum(vals)
                    curr_stat[name] = {"idle": idle, "total": total}
        prev_stat = curr_stat

    def calc_perc(curr, prev):
        total_diff = curr.get("total", 0) - prev.get("total", 0)
        idle_diff = curr.get("idle", 0) - prev.get("idle", 0)
        if total_diff <= 0:
            return 0
        usage = int(round(100.0 * (total_diff - idle_diff) / total_diff))
        return max(0, min(100, usage))

    cpu_overall = calc_perc(curr_stat.get("cpu", {}), prev_stat.get("cpu", {}))
    
    core_usages = []
    core_idx = 0
    while f"cpu{core_idx}" in curr_stat:
        name = f"cpu{core_idx}"
        core_usages.append(calc_perc(curr_stat[name], prev_stat.get(name, {})))
        core_idx += 1

    mem_total, mem_avail = 0, 0
    with open("/proc/meminfo", "r") as f:
        for line in f:
            if line.startswith("MemTotal:"):
                mem_total = int(line.split()[1])
            elif line.startswith("MemAvailable:"):
                mem_avail = int(line.split()[1])
    mem_perc = int(round(100.0 * (mem_total - mem_avail) / mem_total)) if mem_total > 0 else 0

    temps = []
    for p in glob.glob("/sys/class/hwmon/hwmon*/temp*_input") + glob.glob("/sys/class/thermal/thermal_zone*/temp"):
        try:
            with open(p, "r") as f:
                v = int(f.read().strip())
                if 10000 <= v <= 115000:
                    temps.append(v // 1000)
                elif 10 <= v <= 115:
                    temps.append(v)
        except Exception:
            pass
    cpu_temp = max(temps) if temps else 0

    core_temps = [cpu_temp] * len(core_usages)

    with open("/proc/loadavg", "r") as f:
        load = float(f.read().split()[0])
    num_cores = len(core_usages) or 1
    load_perc = int(round((load / num_cores) * 100))

    cpu_model = ""
    curr_freq_mhz = 0
    with open("/proc/cpuinfo", "r") as f:
        for line in f:
            if "model name" in line and not cpu_model:
                cpu_model = line.split(":", 1)[1].strip()
            elif "cpu MHz" in line and curr_freq_mhz == 0:
                try:
                    curr_freq_mhz = float(line.split(":", 1)[1].strip())
                except Exception:
                    pass
    freq_str = f"{round(curr_freq_mhz/1000, 2)}GHz" if curr_freq_mhz else "N/A"

    os_name = "NixOS"
    if os.path.exists("/etc/os-release"):
        with open("/etc/os-release", "r") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    os_name = line.split("=", 1)[1].strip().strip("\"")
    kernel = os.uname().release

    ip_addr = ""
    try:
        out = subprocess.check_output(["ip", "addr", "show"], text=True)
        for line in out.splitlines():
            line = line.strip()
            if line.startswith("inet ") and not line.startswith("inet 127."):
                ip_addr = line.split()[1]
                break
    except Exception:
        pass

    fs_perc = 0
    try:
        out = subprocess.check_output(["df", "-P", "/home", "/nix/store", "/"], text=True)
        for line in out.splitlines():
            if not line.startswith("Filesystem") and "tmpfs" not in line:
                parts = line.split()
                if len(parts) >= 5 and parts[4].endswith("%"):
                    fs_perc = int(parts[4].rstrip("%"))
                    break
    except Exception:
        pass

    return {
        "cpu": cpu_overall,
        "mem": mem_perc,
        "temp": cpu_temp,
        "load": load,
        "load_perc": load_perc,
        "fs": fs_perc,
        "cpu_model": cpu_model,
        "freq": freq_str,
        "arch": os_name,
        "kernel": kernel,
        "ip": ip_addr,
        "core_usages": core_usages,
        "core_temps": core_temps
    }

print(json.dumps(get_stats()))
'
