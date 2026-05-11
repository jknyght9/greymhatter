# Credentials & Paths

## Default Credentials

```
Username: hatter
Password: H@tt3r123!
```

Used for system login, Timesketch, and Yeti.

!!! warning
    Change the default password after first login, especially if the VM is network-accessible.

## Important Paths

| Path | Purpose |
|---|---|
| `/opt/tools/` | CLI tool binaries |
| `~/.local/bin/` | Symlinks to tools for PATH access |
| `/opt/share/` | Evidence and timeline working directory |
| `/opt/share/hayabusa/` | Hayabusa output directory |
| `/opt/share/plaso/` | Plaso timeline storage |
| `/opt/timesketch/` | Timesketch installation |
| `/opt/yeti-docker/prod/` | Yeti installation |
| `/opt/courses/` | Course materials |
| `~/.config/fish/config.fish` | Fish shell functions and aliases |

## Container Services

| Service | Port | Protocol | Auto-start | Start/Stop |
|---|---|---|---|---|
| Homepage | 3000 | HTTP | Yes | — |
| Course Materials | 8000 | HTTP | Yes | `course-update` |
| CyberChef | 8080 | HTTP | Yes | — |
| Timesketch | 443 | HTTPS | No | `starttimesketch` / `stoptimesketch` |
| Yeti | 8888 | HTTPS | No | `startyeti` / `stopyeti` |
| SpiderFoot | 5001 | HTTP | No | `startspiderfoot` / `stopspiderfoot` |

!!! info "Yeti on ARM64"
    Yeti requires SSE4.2 and AVX CPU instructions and is only available on AMD64 systems.
