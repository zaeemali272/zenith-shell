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
        if (line ~ /^cpu /) {
            n = split(line, f, " ")
            idle = f[5] + f[6]
            total = 0
            for (i=2; i<=n; i++) total += f[i]
            curr_idle["cpu"] = idle
            curr_total["cpu"] = total
            print "cpu", idle, total > prev_file
            break
        }
    }
    close("/proc/stat")
    close(prev_file)

    t_diff = curr_total["cpu"] - prev_total["cpu"]
    i_diff = curr_idle["cpu"] - prev_idle["cpu"]
    cpu_overall = (t_diff > 0) ? int(0.5 + 100 * (t_diff - i_diff) / t_diff) : 0
    if (cpu_overall < 0) cpu_overall = 0
    if (cpu_overall > 100) cpu_overall = 100

    mem_total = 0; mem_avail = 0
    while ((getline line < "/proc/meminfo") > 0) {
        if (line ~ /^MemTotal:/) mem_total = $2
        else if (line ~ /^MemAvailable:/) mem_avail = $2
    }
    close("/proc/meminfo")
    mem_perc = (mem_total > 0) ? int(0.5 + 100 * (mem_total - mem_avail) / mem_total) : 0

    max_temp = 0
    cmd = "cat /sys/class/hwmon/hwmon*/temp*_input /sys/class/thermal/thermal_zone*/temp 2>/dev/null"
    while ((cmd | getline line) > 0) {
        t = line + 0
        if (t >= 10000 && t <= 115000) t = int(t / 1000)
        if (t > max_temp && t <= 115) max_temp = t
    }
    close(cmd)

    printf "{\"cpu\": %d, \"mem\": %d, \"temp\": %d}\n", cpu_overall, mem_perc, max_temp
}'
