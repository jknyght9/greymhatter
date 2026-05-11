# Software Reference

Complete list of software installed on GreymHatter, with pinned versions where applicable.

## Forensic Analysis

| Software | Version | Purpose | Source |
|---|---|---|---|
| Hayabusa | 3.9.0 | Windows Event Log timeline analysis | [GitHub](https://github.com/Yamato-Security/hayabusa) |
| Sleuthkit | 4.15.0 | Disk image analysis (`fls`, `mmls`, `icat`, `img_stat`) | [sleuthkit.org](https://sleuthkit.org/) |
| Volatility 3 | stable | Memory forensics framework | [GitHub](https://github.com/volatilityfoundation/volatility3) |
| Volatility 2 | 2.6.1 | Legacy memory forensics (Docker container) | [GitHub](https://github.com/volatilityfoundation/volatility) |
| bulk_extractor | latest | Bulk feature extraction from disk images | [GitHub](https://github.com/simsong/bulk_extractor) |
| ewftools | system | EWF/E01 forensic image mounting and verification | Fedora repos |
| Plaso / log2timeline | latest | Super timeline creation (via Timesketch worker) | [GitHub](https://github.com/log2timeline/plaso) |

## Malware Analysis

| Software | Version | Purpose | Source |
|---|---|---|---|
| capa | 9.4.0 | Executable capability detection | [GitHub](https://github.com/mandiant/capa) |
| FLOSS | 3.1.1 | Obfuscated string extraction | [GitHub](https://github.com/mandiant/flare-floss) |
| YARA | latest | Pattern matching for malware research | [GitHub](https://github.com/VirusTotal/yara) |
| ClamAV | system | Antivirus scanner | Fedora repos |

## Threat Intelligence & OSINT

| Software | Version | Purpose | Source |
|---|---|---|---|
| Timesketch | latest | Collaborative forensic timeline analysis | [GitHub](https://github.com/google/timesketch) |
| Yeti | latest | Threat intelligence platform (AMD64 only) | [GitHub](https://github.com/yeti-platform/yeti) |
| SpiderFoot | latest | OSINT reconnaissance platform | [GitHub](https://github.com/smicallef/spiderfoot) |
| vt-cli | 1.3.0 | VirusTotal command-line interface | [GitHub](https://github.com/VirusTotal/vt-cli) |

## Data Processing

| Software | Version | Purpose | Source |
|---|---|---|---|
| yq | 4.53.2 | YAML/JSON/XML processor | [GitHub](https://github.com/mikefarah/yq) |
| CyberChef | latest | Web-based data transformation tool | [GitHub](https://github.com/gchq/CyberChef) |
| ImHex | system | GUI hex editor for binary analysis | [GitHub](https://github.com/WerWolv/ImHex) |

## Encryption & Mounting

| Software | Version | Purpose | Source |
|---|---|---|---|
| VeraCrypt | system | Encrypted volume management | [veracrypt.fr](https://www.veracrypt.fr/) |
| libbde (bdemount) | latest | BitLocker volume mounting | [GitHub](https://github.com/libyal/libbde) |
| libfvde (fvdemount) | latest | FileVault volume mounting | [GitHub](https://github.com/libyal/libfvde) |
| libvmdk | latest | VMware VMDK image access | [GitHub](https://github.com/libyal/libvmdk) |
| libvhdi | latest | VHD/VHDX image access | [GitHub](https://github.com/libyal/libvhdi) |

## DFIR Utilities

| Software | Version | Purpose | Source |
|---|---|---|---|
| DFIR-PSTools | latest | PowerShell DFIR utilities (timestamps, hash lookups) | [GitLab](https://gitlab.com/jknyght9/dfir-pstools) |
| clamav-hashbuilder | latest | ClamAV signature to Autopsy hashset converter | [GitHub](https://github.com/jknyght9/clamav-hashbuilder) |
| PowerShell | 7+ | Cross-platform scripting | [Microsoft](https://github.com/PowerShell/PowerShell) |

## Shell & Terminal

| Software | Version | Purpose | Source |
|---|---|---|---|
| Fish | system | Default shell | Fedora repos |
| Ghostty | system | Terminal emulator | [ghostty.org](https://ghostty.org/) |
| Starship | latest | Cross-shell prompt | [starship.rs](https://starship.rs/) |
| tmux | system | Terminal multiplexer | Fedora repos |
| Neovim | system | Text editor | Fedora repos |
| bat | system | `cat` replacement with syntax highlighting | Fedora repos |
| eza | 0.23.4 | `ls` replacement with icons | [GitHub](https://github.com/eza-community/eza) |
| ripgrep | system | Fast `grep` replacement | Fedora repos |
| duf | system | `df` replacement with better formatting | Fedora repos |
| btop | system | Interactive process monitor | Fedora repos |
| ctop | 0.7.7 | Docker container monitor | [GitHub](https://github.com/bcicen/ctop) |
| fastfetch | system | System information display | Fedora repos |

## Desktop Environment

| Software | Version | Purpose | Source |
|---|---|---|---|
| XFCE | system | Desktop environment | Fedora repos |
| Plank | system | Application dock | Fedora repos |
| Conky | system | Desktop system monitor | Fedora repos |
| LightDM | system | Display manager | Fedora repos |
| slick-greeter | system | Login screen | Fedora repos |
| Ulauncher | system | Application launcher | Fedora repos |
| Qogir theme | latest | GTK/icon/cursor theme | [GitHub](https://github.com/vinceliuice/Qogir-theme) |
| Hack Nerd Font | 3.1.1 | Terminal/panel font | [GitHub](https://github.com/ryanoasis/nerd-fonts) |
| Inter | system | System UI font | Fedora repos |
| Firefox | system | Web browser | Fedora repos |

## Infrastructure

| Software | Version | Purpose | Source |
|---|---|---|---|
| Docker CE | latest | Container runtime | [docker.com](https://docs.docker.com/) |
| Docker Compose | latest | Container orchestration | Included with Docker CE |
| Ansible | system | Configuration management | Fedora repos |
| Samba | system | SMB file sharing | Fedora repos |
| OpenSSH | system | Remote access | Fedora repos |
| firewalld | system | Host firewall | Fedora repos |
