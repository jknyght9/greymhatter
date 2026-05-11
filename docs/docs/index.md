![GreymHatter](assets/greymhatter-banner-white.png#only-dark){ width="400" }
![GreymHatter](assets/greymhatter-banner.png#only-light){ width="400" }

**GreymHatter** is a digital forensics and incident response (DFIR) distribution based on Fedora Linux. Built as a teaching and casework platform, it combines forensic tools and workflow shortcuts into a single VM:

- Timeline development and analysis
- Memory and disk forensics
- Windows event log analysis
- Open Source Intelligence (OSINT) gathering
- Cyber Threat Intelligence (CTI) platforms

## Features

| Category | Details |
|---|---|
| **Desktop** | XFCE with Qogir theme, Plank dock, Conky system monitor, Ghostty terminal |
| **Forensic Tools** | Volatility 2 & 3, Sleuthkit, Hayabusa, bulk_extractor, capa, FLOSS, YARA |
| **Platforms** | Timesketch, Yeti, SpiderFoot, CyberChef |
| **Shell** | Fish with pre-configured DFIR helper functions and aliases |
| **Architecture** | Full support for AMD64 and ARM64 (Apple Silicon) |
| **Automation** | Packer + Ansible for reproducible VM builds |

## Quick Start

1. Download the latest OVA for your architecture
2. Import into VMware Workstation or Fusion
3. Log in with `hatter` / `H@tt3r123!`
4. Open the Homepage dashboard at `http://localhost:3000`

[:octicons-arrow-right-24: Installation](getting-started/installation.md)

## Legal

This platform was developed for instructional purposes and has not been tested in a production environment. The authors and maintainers are not responsible for loss of data or productivity while using this product.
