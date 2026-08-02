#!/usr/bin/env bash

exec awk '
BEGIN {
    prev_file = "/tmp/zenith_proc_stat.txt"
    while ((getline line < prev_file) > 0) {
        split(line, f, " ")
        prev_idle[f[1]] = f[2]
        prev_total[f[1]] = f[3]
    }
    close(prev_file)

    while ((getline line < "/proc/stat") > 0) {
        if (line ~ /^cpu[0-9]*/) {
            n = split(line, f, " ")
            name = f[1]
            idle = f[5] + f[6]
            total = 0
            for (i=2; i<=n; i++) total += f[i]
            curr_idle[name] = idle
            curr_total[name] = total
            print name, idle, total > prev_file
        }
    }
    close("/proc/stat")
    close(prev_file)

    t_diff = curr_total["cpu"] - prev_total["cpu"]
    i_diff = curr_idle["cpu"] - prev_idle["cpu"]
    cpu_overall = (t_diff > 0) ? int(0.5 + 100 * (t_diff - i_diff) / t_diff) : 0
    if (cpu_overall < 0) cpu_overall = 0
    if (cpu_overall > 100) cpu_overall = 100

    core_idx = 0
    core_json = ""
    while (("cpu" core_idx) in curr_total) {
        name = "cpu" core_idx
        ct_diff = curr_total[name] - prev_total[name]
        ci_diff = curr_idle[name] - prev_idle[name]
        c_usage = (ct_diff > 0) ? int(0.5 + 100 * (ct_diff - ci_diff) / ct_diff) : 0
        if (c_usage < 0) c_usage = 0
        if (c_usage > 100) c_usage = 100
        core_json = (core_json == "") ? c_usage : (core_json ", " c_usage)
        core_idx++
    }

    mem_total = 0; mem_avail = 0
    while ((getline line < "/proc/meminfo") > 0) {
        if (line ~ /^MemTotal:/) mem_total = $2
        else if (line ~ /^MemAvailable:/) mem_avail = $2
    }
    close("/proc/meminfo")
    mem_perc = (mem_total > 0) ? int(0.5 + 100 * (mem_total - mem_avail) / mem_total) : 0

    getline line < "/proc/loadavg"
    close("/proc/loadavg")
    split(line, f, " ")
    load = f[1] + 0
    num_cores = (core_idx > 0) ? core_idx : 1
    load_perc = int(0.5 + (load / num_cores) * 100)

    cpu_model = ""; freq_mhz = 0
    while ((getline line < "/proc/cpuinfo") > 0) {
        if (cpu_model == "" && line ~ /model name/) {
            sub(/^.*:[ \t]*/, "", line)
            gsub(/"/, "\\\"", line)
            cpu_model = line
        }
        else if (freq_mhz == 0 && line ~ /cpu MHz/) {
            split(line, f, ":")
            freq_mhz = f[2] + 0
        }
    }
    close("/proc/cpuinfo")
    freq_str = (freq_mhz > 0) ? sprintf("%.2fGHz", freq_mhz / 1000) : "N/A"

    os_name = "Linux"
    if ((getline line < "/etc/os-release") > 0) {
        close("/etc/os-release")
        while ((getline line < "/etc/os-release") > 0) {
            if (line ~ /^PRETTY_NAME=/) {
                sub(/^PRETTY_NAME="/, "", line)
                sub(/"$/, "", line)
                os_name = line
            }
        }
        close("/etc/os-release")
    }
    getline kernel < "/proc/sys/kernel/osrelease"
    close("/proc/sys/kernel/osrelease")

    max_temp = 0
    cmd = "cat /sys/class/hwmon/hwmon*/temp*_input /sys/class/thermal/thermal_zone*/temp 2>/dev/null"
    while ((cmd | getline line) > 0) {
        t = line + 0
        if (t >= 10000 && t <= 115000) t = int(t / 1000)
        if (t > max_temp && t <= 115) max_temp = t
    }
    close(cmd)

    core_temp_json = ""
    for (i = 0; i < core_idx; i++) {
        core_temp_json = (core_temp_json == "") ? max_temp : (core_temp_json ", " max_temp)
    }

    ip_addr = ""
    cmd_ip = "hostname -I 2>/dev/null"
    if ((cmd_ip | getline line) > 0) {
        split(line, f, " ")
        ip_addr = f[1]
    }
    close(cmd_ip)

    fs_perc = 0
    cmd_df = "df -P / 2>/dev/null"
    while ((cmd_df | getline line) > 0) {
        if (line !~ /^Filesystem/) {
            split(line, f, " ")
            sub(/%/, "", f[5])
            fs_perc = f[5] + 0
        }
    }
    close(cmd_df)

    printf "{\"cpu\": %d, \"mem\": %d, \"temp\": %d, \"load\": %.2f, \"load_perc\": %d, \"fs\": %d, \"cpu_model\": \"%s\", \"freq\": \"%s\", \"arch\": \"%s\", \"kernel\": \"%s\", \"ip\": \"%s\", \"core_usages\": [%s], \"core_temps\": [%s]}\n", \
        cpu_overall, mem_perc, max_temp, load, load_perc, fs_perc, cpu_model, freq_str, os_name, kernel, ip_addr, core_json, core_temp_json
}'
