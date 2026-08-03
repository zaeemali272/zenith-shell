<p align="center">
  <img src="assets/screenshots/bar.png" alt="Zenith Shell Bar">
</p>

<p align="center">
  <sub><sup><img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Telegram-Animated-Emojis/main/Activity/Sparkles.webp" alt="Sparkles" width="25" height="25"/></sup></sub>
  <a href="https://github.com/hyprwm/Hyprland">
    <img src="https://img.shields.io/badge/A%20hackable%20shell%20for-Hyprland-0092CD?style=for-the-badge&logo=linux&color=0092CD&logoColor=D9E0EE&labelColor=000000" alt="A hackable shell for Hyprland">
  </a>
  <a href="https://github.com/outfoxxed/quickshell">
    <img src="https://img.shields.io/badge/Powered%20by-Quickshell-FF616D?style=for-the-badge&logo=qt&color=FF616D&logoColor=FFFFFF&labelColor=000000" alt="Powered by Quickshell">
  </a>
  <sub><sup><img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Telegram-Animated-Emojis/main/Activity/Sparkles.webp" alt="Sparkles" width="25" height="25"/></sup></sub>
</p>

<div align=center>

![GitHub last commit](https://img.shields.io/github/last-commit/zaeemali272/zenith-shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![GitHub Repo stars](https://img.shields.io/github/stars/zaeemali272/zenith-shell?style=for-the-badge&labelColor=101418&color=b9c8da)
![GitHub repo size](https://img.shields.io/github/repo-size/zaeemali272/zenith-shell?style=for-the-badge&labelColor=101418&color=d3bfe6)

</div>

---

# 🌌 Zenith Shell

**Zenith Shell** is a modern, modular, high-performance desktop shell custom-built for **Hyprland** using **Quickshell** (Qt6/QML). Designed with sleek glassmorphism aesthetic, anti-aliased dynamic animations, real-time system monitoring, and instant control popups over IPC.

---

<h2><sub><img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Camera%20with%20Flash.png" alt="Camera with Flash" width="25" height="25" /></sub> Screenshots</h2>

<table align="center">
  <tr>
    <td colspan="4"><img src="assets/screenshots/main.png" alt="Main Desktop Overview"></td>
  </tr>
  <tr>
    <td colspan="1"><img src="assets/screenshots/control-center.png" alt="Control Center"></td>
    <td colspan="1"><img src="assets/screenshots/wallpaper.png" alt="Wallpaper Selector"></td>
    <td colspan="1" align="center"><img src="assets/screenshots/power-profile.png" alt="Power Profile"></td>
    <td colspan="1" align="center"><img src="assets/screenshots/bluetooth.png" alt="Bluetooth Manager"></td>
  </tr>
</table>

---

<h2>Technology Stack & Architecture</h2>

Zenith Shell leverages native Wayland protocols and modular QML singletons for near-zero idle resource utilization:

- **UI Framework**: [Quickshell](https://github.com/outfoxxed/quickshell) (Qt6 QML engine with native Wayland Layer Shell, Foreign Toplevel, and Screencopy bindings).
- **Compositor Integration**: Hyprland IPC sockets for real-time workspace state, active window tracking, and monitor scaling.
- **Design System**: Responsive QML design system with dynamic scaling (`Theme.scaled()`), glassmorphic overlays, and customizable Catppuccin-inspired color palettes.
- **IPC Control System**: Non-blocking asynchronous Named Pipe (FIFO) IPC at `~/.cache/zenith_fifo` managed via `launch.sh`.
- **Media Engine**: Native Python & `ffmpeg` pipeline for high-performance rounded-corner wallpaper thumbnail generation.

---

<h2><sub><img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Package.png" alt="Package" width="25" height="25" /></sub> System Requirements & Dependencies</h2>

Ensure the following packages are installed on your Linux system:

### Core Requirements
| Component | Package / Dependency | Purpose |
|---|---|---|
| **Shell Engine** | `quickshell` | Qt6/QML shell environment |
| **Compositor** | `hyprland` | Wayland window manager |
| **GUI Framework** | `qt6-declarative`, `qt6-svg`, `qt6-5compat` | QML engine and vector icon rendering |

### System Daemons & Utilities
| Category | Dependencies | Description |
|---|---|---|
| **Wallpapers** | `awww` / `swww`, `mpvpaper`, `ffmpeg` | Static/animated wallpapers & thumbnail generator |
| **Network** | `networkmanager` (`nmcli`) or `iwd` (`iwctl`), `rfkill` | Wi-Fi scanning, connecting & airplane mode |
| **Bluetooth** | `bluez`, `bluez-utils` (`bluetoothctl`) | Device discovery and connection management |
| **Audio & Media** | `pipewire`, `wireplumber`, `playerctl` | System volume control & MPRIS metadata |
| **Power** | `upower`, `power-profiles-daemon` | Battery level tracking & power profile switching |
| **Helper Runtime** | `python3`, `python-pillow`, `jq` | Async backend scripts & JSON parsing |

---

<h2><sub><img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Rocket.png" alt="Rocket" width="25" height="25" /></sub> Installation & Setup</h2>

### 1. Clone Repository
Clone Zenith Shell into your user configuration directory:
```bash
git clone https://github.com/zaeemali272/zenith-shell.git ~/.config/quickshell
```

### 2. Make Launcher Executable
```bash
chmod +x ~/.config/quickshell/launch.sh
chmod +x ~/.config/quickshell/scripts/*.sh
```

### 3. Autostart in Hyprland
Add the following line to your `hyprland.conf`:
```ini
exec-once = ~/.config/quickshell/launch.sh start
```

---

### ❄️ NixOS & Home Manager (Flakes)

Zenith Shell includes a `flake.nix` with Home Manager module support.

#### 1. Add as a Flake Input
In your NixOS system or Home Manager `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zenith-shell.url = "github:zaeemali272/zenith-shell"; # or "git+file:///path/to/local/zenith-shell"
  };

  outputs = { self, nixpkgs, zenith-shell, ... }: {
    homeConfigurations."user" = home-manager.lib.homeManagerConfiguration {
      modules = [
        zenith-shell.homeManagerModules.default
        {
          programs.zenith-shell.enable = true;
        }
      ];
    };
  };
}
```

#### 2. Automatic Updates on `nixos-rebuild`

To automatically fetch and apply updates to Zenith Shell whenever you run `nixos-rebuild`:

- **Updating Remote Flake**: Pass `--update-input` to `nixos-rebuild`:
  ```bash
  sudo nixos-rebuild switch --flake . --update-input zenith-shell
  ```
  *or update lock file explicitly:*
  ```bash
  nix flake update zenith-shell
  sudo nixos-rebuild switch --flake .
  ```

- **Live Local Development**: Point your input to your local git repository:
  ```nix
  zenith-shell.url = "git+file:///home/zaeem/.config/quickshell";
  ```
  Every time you commit changes locally and run `sudo nixos-rebuild switch --flake .`, Nix automatically builds and applies your latest version.


---

<h2><sub><img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Symbols/Input%20Latin%20Uppercase.png" alt="Keyboard" width="25" height="25" /></sub> How to Open Menus & IPC Commands</h2>

Zenith Shell comes with a built-in launcher script (`launch.sh`) that communicates directly with the running shell via IPC. You can bind these commands to Hyprland keybindings or run them from terminal.

### IPC Command Commands

| Action / Menu | Command | Description |
|---|---|---|
| **Dashboard / Launcher** | `~/.config/quickshell/launch.sh overview` | Toggle app grid & overview workspace window |
| **Wallpaper Selector** | `~/.config/quickshell/launch.sh wallpaper` | Open static & live wallpaper chooser |
| **Quick Settings** | `~/.config/quickshell/launch.sh controlcenter` | Toggle main Quick Settings control center |
| **Wi-Fi / Network** | `~/.config/quickshell/launch.sh wifi` | Open Wi-Fi scan and connection menu |
| **Bluetooth** | `~/.config/quickshell/launch.sh bluetooth` | Open Bluetooth paired & available devices menu |
| **Volume / Audio** | `~/.config/quickshell/launch.sh volume` | Open audio output/input sliders popup |
| **Power Profile** | `~/.config/quickshell/launch.sh powerprofile` | Switch between Performance, Balanced & Power-saver |
| **Battery Details** | `~/.config/quickshell/launch.sh battery` | Open battery health & status popup |
| **Power Menu** | `~/.config/quickshell/launch.sh power` | Open Lock, Logout, Reboot, Shutdown menu |
| **Pomodoro & Todo** | `~/.config/quickshell/launch.sh pomodoro` | Open Pomodoro timer & task manager |
| **Settings App** | `~/.config/quickshell/launch.sh settings` | Open Zenith Shell configuration window |
| **Close All Menus** | `~/.config/quickshell/launch.sh close` | Instantly close any open popups or overlays |

---

### Recommended Hyprland Keybindings

Add these bindings to your `~/.config/hypr/hyprland.conf` or `keybinds.conf`:

```ini
# Zenith Shell Keybindings
$qs = ~/.config/quickshell/launch.sh

bind = SUPER, TAB, exec, $qs overview
bind = SUPER, W, exec, $qs wallpaper
bind = SUPER, V, exec, $qs volume
bind = SUPER, N, exec, $qs wifi
bind = SUPER, B, exec, $qs bluetooth
bind = SUPER, P, exec, $qs powerprofile
bind = SUPER, ESCAPE, exec, $qs power
bind = SUPER, S, exec, $qs settings
```

---

<h2><sub><img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Gear.png" alt="Features" width="25" height="25" /></sub> Key Features</h2>

- [x] **Dynamic Top Bar**: Active workspace indicator, window title, system stats, media ticker, tray icons, and clock.
- [x] **Wallpaper Manager**: Real-time thumbnail preview for images and live video wallpapers (`.mp4`, `.mkv`, `.webm`) using `mpvpaper`.
- [x] **Control Center**: Integrated quick toggles for Wi-Fi, Bluetooth, Airplane mode, Night Light, and Volume.
- [x] **Workspaces Overview**: Visual app launcher grid and workspace switcher integrated with Hyprland IPC.
- [x] **System Stats & Monitoring**: Live CPU, RAM, Disk, Temperature, and Network speed meters.
- [x] **MPRIS Media Controller**: Album artwork, track info, seekbar, and playback controls.
- [x] **Pomodoro & Todo Widget**: Built-in focus timer with task list management.
- [x] **Adaptive Theme System**: Modular Catppuccin color palette with smooth glassmorphism borders and blur.

---

<h2><sub><img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Telegram-Animated-Emojis/main/Activity/Sparkles.webp" alt="Sparkles" width="25" height="25"/></sub> Inspired By</h2>

- [Axenide/Ax-Shell](https://github.com/Axenide/Ax-Shell)
- [caelestia-dots/shell](https://github.com/caelestia-dots/shell)
- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)

