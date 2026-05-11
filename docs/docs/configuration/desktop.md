# Desktop Environment

## XFCE Desktop

GreymHatter uses XFCE with the following customizations:

| Component | Configuration |
|---|---|
| **Theme** | Qogir-Dark (GTK + window manager) |
| **Icons** | Qogir-Dark |
| **Cursors** | Qogir-Dark |
| **Font** | Inter (system), Hack Nerd Font Mono (panel/terminal) |
| **Terminal** | Ghostty with Fish shell |
| **Dock** | Plank with Arc theme |
| **System Monitor** | Conky with Nord colors |
| **Login Screen** | LightDM + slick-greeter |
| **Resolution** | 1920x1080 default |

## Plank Dock

The dock appears at the bottom of the screen with icons for commonly used applications. It uses the Arc theme and intelligent auto-hide.

## Conky

The system monitor widget displays in the top-right corner:

- CPU and memory usage
- Disk usage
- Network activity
- Docker service status
- System uptime and time (UTC + local)

Configuration: `~/.config/conky/conkyrc`

## Ghostty Terminal

Ghostty is the default terminal emulator with Fish shell. Configuration is at `~/.config/ghostty/config`.

## Ulauncher

Application launcher accessible via ++shift+ctrl+space++.
