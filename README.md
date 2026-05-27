![greymhatter-logo](./media/v2/logo/greymhatter-banner.png)

# GreymHatter

A digital forensics and incident response (DFIR) distribution based on Fedora Linux. Built as a teaching and casework platform, GreymHatter integrates forensic tools, analysis platforms, and workflow automation into a single deployable VM.

[Read the Documentation Here](https://jknyght9.github.io/greymhatter/)

## Features

- **XFCE desktop** with Qogir theme, Plank dock, Conky system monitor
- **Ghostty terminal** with Fish shell and pre-configured DFIR helper functions
- **Forensic tools**: Hayabusa, Sleuthkit (VMDK/VHD), Volatility 2 & 3, capa, FLOSS, bulk_extractor, yq
- **Analysis platforms**: Timesketch, Yeti, SpiderFoot, CyberChef (Docker containers)
- **Course delivery**: MkDocs-based course materials served locally
- **Dual architecture**: AMD64 and ARM64 (Apple Silicon) support
- **Automated builds**: Packer + Ansible for reproducible VM images

## Quick Start

Download the latest OVA and import into VMware Workstation or Fusion.

```
Username: hatter
Password: H@tt3r123!
```

## Building from Source

### Prerequisites

- [Packer](https://developer.hashicorp.com/packer/install) (`brew install hashicorp/tap/packer`)
- [Docker](https://www.docker.com/) (for MkDocs and tool compilation)
- Proxmox server (AMD64 builds) or VMware Fusion (ARM64 builds)

### Build Pipeline

```bash
# AMD64 (Proxmox)
make base-amd64          # Stage 1: ISO → base template (run once)
make build-amd64         # Stage 2: Clone → Ansible → final template
make export-amd64        # Stage 3: Template → OVA

# ARM64 (VMware Fusion)
make build-arm64-base    # Stage 1: ISO → base VM (run once)
make build-arm64         # Stage 2: Boot base → Ansible → final VM
make export-arm64        # Stage 3: VM → OVA

# Development (fast iteration)
make dev DEV_VM_IP=<ip>  # SCP + Ansible on a live VM
```

### Testing

```bash
make test DEV_VM_IP=<ip>         # Automated pass/fail
make test-manual DEV_VM_IP=<ip>  # Verbose output for manual review
```

### Documentation

```bash
make docs                # Preview at http://localhost:8000
```

## Architecture

```
greymhatter/
├── ansible/             # Ansible playbook and roles (9 roles)
│   ├── roles/base/      # OS config, packages, firewall
│   ├── roles/docker/    # Docker CE, daemon config
│   ├── roles/desktop/   # XFCE, Plank, conky, theming
│   ├── roles/user/      # User creation, dotfiles, fish shell
│   ├── roles/tools/     # DFIR tools (compiled via Docker builder)
│   ├── roles/containers/ # Timesketch, Yeti, SpiderFoot, CyberChef
│   ├── roles/courses/   # MkDocs course material delivery
│   ├── roles/samba/     # SMB file sharing
│   └── roles/verify/    # Post-install verification + manifest
├── packer/              # Packer templates (Proxmox + Fusion)
├── docs/                # Project documentation (MkDocs)
├── home/                # User dotfiles (fish, ghostty, tmux, nvim)
├── docker/              # Docker Compose files for services
├── media/v2/            # Logos, backgrounds, branding
├── tests/               # Integration test suite
└── Makefile             # Build targets
```

## Container Services

| Service | Port | Auto-start | Start Command |
|---|---|---|---|
| Homepage | 3000 | Yes | — |
| CyberChef | 8080 | Yes | — |
| Courses | 8000 | Yes | — |
| Timesketch | 443 | No | `starttimesketch` |
| Yeti | 8888 | No | `startyeti` |
| SpiderFoot | 5001 | No | `startspiderfoot` |

## Updating a Deployed VM

```fish
greymhatter-update
```

## Legal

This platform was developed for instructional purposes and has not been tested in a production environment. The authors and maintainers of this project are not responsible for loss of data or productivity while using this product.
