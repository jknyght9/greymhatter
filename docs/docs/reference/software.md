# Software Reference

Complete list of software installed on GreymHatter, with pinned versions where applicable.

## Forensic Analysis

| Software | Version | Purpose | Source |
|---|---|---|---|
| bulk_extractor | latest | Bulk feature extraction from disk images | [GitHub](https://github.com/simsong/bulk_extractor) |
| ewftools | system | EWF/E01 forensic image mounting and verification | Fedora repos |
| Hayabusa | 3.9.0 | Windows Event Log timeline analysis | [GitHub](https://github.com/Yamato-Security/hayabusa) |
| Plaso / log2timeline | latest | Super timeline creation (via Timesketch worker) | [GitHub](https://github.com/log2timeline/plaso) |
| Sleuthkit | 4.15.0 | Disk image analysis (`fls`, `mmls`, `icat`, `img_stat`) | [sleuthkit.org](https://sleuthkit.org/) |
| Volatility 2 | 2.6.1 | Legacy memory forensics (Docker container) | [GitHub](https://github.com/volatilityfoundation/volatility) |
| Volatility 3 | stable | Memory forensics framework | [GitHub](https://github.com/volatilityfoundation/volatility3) |

## Eric Zimmerman Tools

Cross-platform .NET 9 builds, installed via `Get-ZimmermanTools.ps1` into `/opt/tools/ezimmerman/net9/` and invoked through wrapper scripts in `~/.local/bin/`. Runs on both amd64 and arm64.

| Software | Version | Purpose | Source |
|---|---|---|---|
| AmcacheParser | latest | Windows Amcache.hve parser | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| AppCompatCacheParser | latest | Shimcache / AppCompatCache parser | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| bstrings | latest | Better strings (unicode-aware) | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| EvtxECmd | latest | Windows Event Log (EVTX) parser | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| iisGeolocate | latest | IIS log geolocation | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| JLECmd | latest | Jump List parser | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| LECmd | latest | LNK shortcut parser | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| MFTECmd | latest | $MFT / $J / $Boot / $SDS / $LogFile parser | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| PECmd | latest | Prefetch parser | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| RBCmd | latest | Recycle Bin parser | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| RecentFileCacheParser | latest | RecentFileCache.bcf parser | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| RECmd | latest | Registry hive parser (ships with BatchExamples) | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| rla | latest | Registry Live Agent | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| SBECmd | latest | ShellBag parser | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| SQLECmd | latest | SQLite parser (maps included) | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| SrumECmd | latest | SRUM (System Resource Usage Monitor) parser | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| SumECmd | latest | Server User Metrics parser | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| VSCMount | latest | Volume Shadow Copy mounter (Windows-only, wrapper present) | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| WxTCmd | latest | Windows 10 timeline (ActivitiesCache.db) parser | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |

Rerun `greymhatter-update` on a running VM to pull the latest tool versions.

## Malware Analysis

| Software | Version | Purpose | Source |
|---|---|---|---|
| capa | 9.4.0 | Executable capability detection | [GitHub](https://github.com/mandiant/capa) |
| ClamAV | system | Antivirus scanner | Fedora repos |
| FLOSS | 3.1.1 | Obfuscated string extraction | [GitHub](https://github.com/mandiant/flare-floss) |
| YARA | latest | Pattern matching for malware research | [GitHub](https://github.com/VirusTotal/yara) |

## Threat Intelligence & OSINT

| Software | Version | Purpose | Source |
|---|---|---|---|
| SpiderFoot | latest | OSINT reconnaissance platform | [GitHub](https://github.com/smicallef/spiderfoot) |
| Timesketch | latest | Collaborative forensic timeline analysis | [GitHub](https://github.com/google/timesketch) |
| vt-cli | 1.3.0 | VirusTotal command-line interface | [GitHub](https://github.com/VirusTotal/vt-cli) |
| Yeti | latest | Threat intelligence platform (AMD64 only) | [GitHub](https://github.com/yeti-platform/yeti) |

## Data Processing

| Software | Version | Purpose | Source |
|---|---|---|---|
| CyberChef | latest | Web-based data transformation tool | [GitHub](https://github.com/gchq/CyberChef) |
| ffmpeg | system | Audio/video processing (full codec set via RPM Fusion) | [rpmfusion.org](https://rpmfusion.org/) |
| ImageMagick | system | Image manipulation suite (`magick`, `convert`) | Fedora repos |
| ImHex | system | GUI hex editor for binary analysis | [GitHub](https://github.com/WerWolv/ImHex) |
| LibreOffice | system | Office document suite (Writer/Calc/Impress/Draw) | Fedora repos |
| mediainfo | system | Media file metadata extraction | Fedora repos |
| p7zip | system | 7zip / RAR archive support (`7z`) | Fedora repos |
| poppler-utils | system | PDF extraction utilities (`pdftotext`, `pdftoppm`) | Fedora repos |
| sqlite3 | system | SQLite database CLI | Fedora repos |
| yq | 4.53.2 | YAML/JSON/XML processor | [GitHub](https://github.com/mikefarah/yq) |

## Encryption & Mounting

| Software | Version | Purpose | Source |
|---|---|---|---|
| libbde (bdemount) | latest | BitLocker volume mounting | [GitHub](https://github.com/libyal/libbde) |
| libfvde (fvdemount) | latest | FileVault volume mounting | [GitHub](https://github.com/libyal/libfvde) |
| libvhdi | latest | VHD/VHDX image access | [GitHub](https://github.com/libyal/libvhdi) |
| libvmdk | latest | VMware VMDK image access | [GitHub](https://github.com/libyal/libvmdk) |
| VeraCrypt | system | Encrypted volume management | [veracrypt.fr](https://www.veracrypt.fr/) |

## DFIR Utilities

| Software | Version | Purpose | Source |
|---|---|---|---|
| clamav-hashbuilder | latest | ClamAV signature to Autopsy hashset converter | [GitHub](https://github.com/jknyght9/clamav-hashbuilder) |
| DFIR-PSTools | latest | PowerShell DFIR utilities (timestamps, hash lookups) | [GitLab](https://gitlab.com/jknyght9/dfir-pstools) |
| PowerShell | 7+ | Cross-platform scripting | [Microsoft](https://github.com/PowerShell/PowerShell) |

## Shell & Terminal

| Software | Version | Purpose | Source |
|---|---|---|---|
| atuin | system | Shell history sync + search | Fedora repos |
| bat | system | `cat` replacement with syntax highlighting | Fedora repos |
| btop | system | Interactive process monitor | Fedora repos |
| chafa | system | Terminal image renderer | Fedora repos |
| ctop | 0.7.7 | Docker container monitor | [GitHub](https://github.com/bcicen/ctop) |
| duf | system | `df` replacement with better formatting | Fedora repos |
| eza | 0.23.4 | `ls` replacement with icons | [GitHub](https://github.com/eza-community/eza) |
| fastfetch | system | System information display | Fedora repos |
| fd | system | Fast `find` replacement (package `fd-find`) | Fedora repos |
| Fish | system | Default shell | Fedora repos |
| fzf | system | Fuzzy finder | Fedora repos |
| Ghostty | system | Terminal emulator | [ghostty.org](https://ghostty.org/) |
| Neovim | system | Text editor | Fedora repos |
| ripgrep | system | Fast `grep` replacement | Fedora repos |
| Starship | latest | Cross-shell prompt | [starship.rs](https://starship.rs/) |
| tmux | system | Terminal multiplexer | Fedora repos |
| xclip | system | X11 clipboard utility | Fedora repos |
| yazi | latest | TUI file manager with previewer integrations | [GitHub](https://github.com/sxyazi/yazi) |
| zoxide | system | Smart `cd` (`z`/`zi` directory jump) | Fedora repos |

## Desktop Environment

| Software | Version | Purpose | Source |
|---|---|---|---|
| Conky | system | Desktop system monitor | Fedora repos |
| Firefox | system | Web browser | Fedora repos |
| Hack Nerd Font | 3.1.1 | Terminal/panel font | [GitHub](https://github.com/ryanoasis/nerd-fonts) |
| Inter | system | System UI font | Fedora repos |
| LightDM | system | Display manager | Fedora repos |
| Plank | system | Application dock | Fedora repos |
| Qogir theme | latest | GTK/icon/cursor theme | [GitHub](https://github.com/vinceliuice/Qogir-theme) |
| slick-greeter | system | Login screen | Fedora repos |
| Ulauncher | system | Application launcher | Fedora repos |
| XFCE | system | Desktop environment | Fedora repos |

## Infrastructure

| Software | Version | Purpose | Source |
|---|---|---|---|
| Ansible | system | Configuration management | Fedora repos |
| .NET Runtime | 9.0 | Runtime for Eric Zimmerman tools | [dot.net](https://dot.net/) |
| Docker CE | latest | Container runtime | [docker.com](https://docs.docker.com/) |
| Docker Compose | latest | Container orchestration | Included with Docker CE |
| firewalld | system | Host firewall | Fedora repos |
| OpenSSH | system | Remote access | Fedora repos |
| Samba | system | SMB file sharing | Fedora repos |
