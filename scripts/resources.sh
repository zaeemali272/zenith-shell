#!/bin/bash

# System Info
cpu_model=$(grep "model name" /proc/cpuinfo | head -n1 | cut -d':' -f2 | xargs)
max_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo "0")
max_freq_ghz=$(echo "scale=2; $max_freq / 1000000" | bc -l)
curr_freq=$(grep "cpu MHz" /proc/cpuinfo | head -n1 | cut -d':' -f2 | xargs)
curr_freq_ghz=$(echo "scale=2; $curr_freq / 1000" | bc -l)

arch=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
kernel=$(uname -r)
ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}')

# Usage
cpu=$(LC_ALL=C top -bn1 | grep "Cpu(s)" | sed 's/[:,]/ /g' | awk '{print int($2 + $4)}')
mem=$(free | awk '/Mem:/ {printf "%d", $3/$2 * 100}')
load=$(awk '{print $1}' /proc/loadavg)
cores=$(nproc)
load_perc=$(awk -v cores="$cores" '{printf "%d", ($1/cores)*100}' /proc/loadavg)

# Per Core Usage (numeric)
core_usages=$(LC_ALL=C top -bn1 -1 | grep "^%Cpu[0-9]" | sed 's/[:,]/ /g' | awk '{print int($2 + $4)}' | jq -s .)

# Temperature
temp=$(sensors | awk '/Package id 0:/ {print int($4)}' | head -n1 | tr -d '+°C')
[ -z "$temp" ] && temp=$(sensors | awk '/Tdie/ {print int($2)}' | head -n1 | tr -d '+°C')
[ -z "$temp" ] && temp=$(sensors | awk '/temp1/ {print int($2)}' | head -n1 | tr -d '+°C')
[ -z "$temp" ] && temp=0

# Per Core Temps (numeric)
core_temps=$(sensors | awk '/Core [0-9]:/ {print int($3)}' | jq -s .)

# Filesystem
fs=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

jq -n \
  --arg cpu "$cpu" \
  --arg mem "$mem" \
  --arg temp "$temp" \
  --arg load "$load" \
  --arg load_perc "$load_perc" \
  --arg fs "$fs" \
  --arg cpu_model "$cpu_model" \
  --arg freq "${curr_freq_ghz}/${max_freq_ghz}GHz" \
  --arg arch "$arch" \
  --arg kernel "$kernel" \
  --arg ip "$ip" \
  --argjson core_usages "$core_usages" \
  --argjson core_temps "$core_temps" \
  '{
    cpu: ($cpu|tonumber),
    mem: ($mem|tonumber),
    temp: ($temp|tonumber),
    load: ($load|tonumber),
    load_perc: ($load_perc|tonumber),
    fs: ($fs|tonumber),
    cpu_model: $cpu_model,
    freq: $freq,
    arch: $arch,
    kernel: $kernel,
    ip: $ip,
    core_usages: $core_usages,
    core_temps: $core_temps
  }'
