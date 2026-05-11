# Tools

## Container Services

Services run as Docker containers and are managed via `docker compose`. Lightweight services auto-start on boot; heavier services are started manually via fish shell functions.

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

## CLI Tools

### Forensic Analysis

| Tool | Purpose | Arch | Source |
|---|---|---|---|
| Hayabusa | Windows Event Log analysis | AMD64, ARM64 | [GitHub](https://github.com/Yamato-Security/hayabusa) |
| Sleuthkit | Disk image analysis (`fls`, `mmls`, `icat`, etc.) | AMD64, ARM64 | [sleuthkit.org](https://sleuthkit.org/) |
| Volatility 3 | Memory forensics | AMD64, ARM64 | [GitHub](https://github.com/volatilityfoundation/volatility3) |
| Volatility 2 | Legacy memory analysis (Docker) | AMD64, ARM64 | [GitHub](https://github.com/volatilityfoundation/volatility) |
| bulk_extractor | Bulk data extraction from disk images | AMD64, ARM64 | [GitHub](https://github.com/simsong/bulk_extractor) |

### Malware Analysis

| Tool | Purpose | Arch | Source |
|---|---|---|---|
| capa | File capability detection | AMD64, ARM64 | [GitHub](https://github.com/mandiant/capa) |
| FLOSS | Obfuscated string extraction | AMD64 | [GitHub](https://github.com/mandiant/flare-floss) |
| YARA | Pattern matching for malware research | AMD64, ARM64 | [GitHub](https://github.com/VirusTotal/yara) |

### Data & Intelligence

| Tool | Purpose | Arch | Source |
|---|---|---|---|
| yq | YAML/JSON/XML processor | AMD64, ARM64 | [GitHub](https://github.com/mikefarah/yq) |
| vt-cli | VirusTotal CLI (requires API key) | AMD64, ARM64 | [GitHub](https://virustotal.github.io/vt-cli/) |
| DFIR-PSTools | PowerShell DFIR utilities | AMD64, ARM64 | [GitLab](https://gitlab.com/jknyght9/dfir-pstools) |
| clamav-hashbuilder | ClamAV → Autopsy hashset builder | AMD64, ARM64 | [GitHub](https://github.com/jknyght9/clamav-hashbuilder) |
| ImHex | GUI hex editor for binary analysis | AMD64, ARM64 | [GitHub](https://github.com/WerWolv/ImHex) |

### Encryption & Mounting

| Tool | Purpose | Arch | Source |
|---|---|---|---|
| VeraCrypt | Encrypted volume management | AMD64, ARM64 | [veracrypt.fr](https://www.veracrypt.fr/) |
| bdemount (libbde) | BitLocker volume mounting | AMD64, ARM64 | [GitHub](https://github.com/libyal/libbde) |
| fvdemount (libfvde) | FileVault volume mounting | AMD64, ARM64 | [GitHub](https://github.com/libyal/libfvde) |
| ewftools | EWF/E01 forensic image tools | AMD64, ARM64 | Fedora repos |

### Utilities

| Tool | Purpose |
|---|---|
| bat | `cat` replacement with syntax highlighting |
| eza | `ls` replacement with icons and tree view |
| duf | `df` replacement with better formatting |
| ripgrep | Fast `grep` replacement |
| hexdump / xxd | Command-line hex dump utilities |
| tmux | Terminal multiplexer |
| Neovim | Text editor (NvChad configuration) |

## Installed Paths

- `/opt/tools/` — CLI tool binaries (hayabusa, capa, etc.)
- `~/.local/bin/` — Symlinks to tools for PATH access
- `/opt/share/` — Evidence and timeline working directory
