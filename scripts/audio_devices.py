#!/usr/bin/env python3
"""Audio sinks and sources with their default flags, as JSON, for VolumeService.

Parses `wpctl status`. If a connected Bluetooth audio device (bluez5) does not
have an active sink because its WirePlumber profile was left in 'off', it
automatically activates the highest priority A2DP sink profile so the device
immediately appears in audio output devices.
"""
import json
import re
import subprocess
import time


def get_desc(dev_id):
    try:
        out = subprocess.check_output(['wpctl', 'inspect', str(dev_id)], text=True, timeout=1)
        for line in out.splitlines():
            if 'node.description' in line:
                m = re.search(r'node\.description\s*=\s*"(.*)"', line)
                if m:
                    return m.group(1)
    except Exception:
        pass
    return ''


def activate_bluez_profile(dev_id):
    try:
        raw = subprocess.check_output(['pw-dump', str(dev_id)], text=True, timeout=1.5)
        data = json.loads(raw)
        for obj in data:
            if obj.get('id') == dev_id and 'info' in obj:
                enum_profiles = obj['info'].get('params', {}).get('EnumProfile', [])
                candidates = []
                for p in enum_profiles:
                    name = p.get('name', '')
                    avail = p.get('available', '')
                    if 'a2dp-sink' in name and avail != 'no':
                        candidates.append((p.get('priority', 0), p.get('index'), name))
                if not candidates:
                    for p in enum_profiles:
                        classes = p.get('classes', [])
                        classes_str = json.dumps(classes)
                        if 'Audio/Sink' in classes_str and p.get('available') != 'no':
                            candidates.append((p.get('priority', 0), p.get('index'), p.get('name', '')))
                if candidates:
                    candidates.sort(reverse=True)
                    best_index = candidates[0][1]
                    subprocess.run(['wpctl', 'set-profile', str(dev_id), str(best_index)], timeout=1.5)
                    return True
    except Exception:
        pass
    return False


def get_devices(auto_fix=True):
    try:
        out = subprocess.check_output(['wpctl', 'status'], text=True, timeout=2)
    except Exception:
        out = ''

    sinks, sources = [], []
    active_sink, active_source = -1, -1

    in_audio = False
    in_devices = False
    in_sinks = False
    in_sources = False

    bluez_devices = {}  # id -> name

    for line in out.splitlines():
        if line.strip().startswith('Audio'):
            in_audio = True
            continue
        elif line.strip().startswith('Video') or line.strip().startswith('Settings'):
            in_audio = False
            in_devices = False
            in_sinks = False
            in_sources = False
            continue

        if not in_audio:
            continue

        if 'Devices:' in line:
            in_devices = True
            in_sinks = False
            in_sources = False
            continue
        elif 'Sinks:' in line:
            in_sinks = True
            in_devices = False
            in_sources = False
            continue
        elif 'Sources:' in line:
            in_sources = True
            in_devices = False
            in_sinks = False
            continue
        elif any(k in line for k in ['Filters:', 'Streams:']):
            in_devices = False
            in_sinks = False
            in_sources = False

        if in_devices:
            m = re.search(r'(\d+)\.\s+(.*?)\s*\[bluez5\]', line)
            if m:
                d_id = int(m.group(1))
                d_name = m.group(2).strip()
                bluez_devices[d_id] = d_name
            continue

        m = re.search(r'(\*?\s*)(\d+)\.\s+(.*?)\s*(\[|$)', line)
        if m and (in_sinks or in_sources):
            is_def = '*' in m.group(1)
            dev_id = int(m.group(2))
            dev_name = m.group(3).strip()

            if not dev_name or dev_name == '(null)' or 'camera' in dev_name.lower():
                continue

            if dev_name.startswith('Built-in Audio'):
                dev_name = 'Built-in Microphone' if in_sources else 'Built-in Speaker'
            elif dev_name.startswith('bluez_'):
                real_desc = get_desc(dev_id)
                if real_desc:
                    dev_name = real_desc

            item = {'id': dev_id, 'name': dev_name, 'isDefault': is_def}
            if in_sinks:
                sinks.append(item)
                if is_def:
                    active_sink = dev_id
            elif in_sources:
                sources.append(item)
                if is_def:
                    active_source = dev_id

    # If any connected bluez device is missing from sinks, activate its profile and retry
    if auto_fix and bluez_devices:
        missing_bluez = []
        for b_id, b_name in bluez_devices.items():
            found = False
            for s in sinks:
                if b_name.lower() in s['name'].lower() or 'bluez' in s['name'].lower() or 'bluetooth' in s['name'].lower():
                    found = True
                    break
            if not found:
                missing_bluez.append(b_id)

        if missing_bluez:
            fixed_any = False
            for b_id in missing_bluez:
                if activate_bluez_profile(b_id):
                    fixed_any = True
            if fixed_any:
                time.sleep(0.15)
                return get_devices(auto_fix=False)

    # Fallback for Bluetooth sinks listed under Filters/Streams if not found in Sinks
    if bluez_devices and not any('bluez' in s['name'].lower() or 'bluetooth' in s['name'].lower() or any(b.lower() in s['name'].lower() for b in bluez_devices.values()) for s in sinks):
        for line in out.splitlines():
            if '[Audio/Sink]' in line and ('bluez' in line or 'bluetooth' in line or any(b.lower() in line.lower() for b in bluez_devices.values())):
                m = re.search(r'(\*?\s*)(\d+)\.\s+(.*?)\s*\[Audio/Sink\]', line)
                if m:
                    is_def = '*' in m.group(1)
                    dev_id = int(m.group(2))
                    real_desc = get_desc(dev_id)
                    dev_name = real_desc if real_desc else 'Bluetooth Headset'
                    item = {'id': dev_id, 'name': dev_name, 'isDefault': is_def}
                    sinks.append(item)
                    if is_def:
                        active_sink = dev_id

    # Fallback for Bluetooth sources listed under Filters
    known_bluez_names = [b.lower() for b in bluez_devices.values()]
    if not any('bluez' in s['name'].lower() or 'bluetooth' in s['name'].lower() or any(b in s['name'].lower() for b in known_bluez_names) for s in sources):
        for line in out.splitlines():
            if '[Audio/Source]' in line and ('bluez' in line or 'bluetooth' in line or any(b in line.lower() for b in known_bluez_names)):
                m = re.search(r'(\*?\s*)(\d+)\.\s+(.*?)\s*\[Audio/Source\]', line)
                if m:
                    is_def = '*' in m.group(1)
                    dev_id = int(m.group(2))
                    real_desc = get_desc(dev_id)
                    dev_name = real_desc if real_desc else 'Bluetooth Microphone'
                    item = {'id': dev_id, 'name': dev_name, 'isDefault': is_def}
                    sources.append(item)
                    if is_def:
                        active_source = dev_id

    return {'sinks': sinks, 'sources': sources, 'activeSinkId': active_sink, 'activeSourceId': active_source}


if __name__ == '__main__':
    print(json.dumps(get_devices()))
