# Build Pipeline

GreymHatter uses a staged Packer + Ansible pipeline for reproducible VM builds.

## Architecture

```mermaid
graph LR
    A[Fedora ISO] -->|Packer + Kickstart| B[Base Template]
    B -->|Clone + Ansible| C[Provisioned VM]
    C -->|Export| D[OVA Distribution]
```

## Prerequisites

- Packer installed locally
- Proxmox server (AMD64 builds)
- VMware Fusion (ARM64 builds)

## Build Targets

```bash
# AMD64 (Proxmox)
make base-amd64          # Stage 1: ISO → base template
make build-amd64         # Stage 2: base → provisioned template
make export-amd64        # Stage 3: export OVA

# ARM64 (VMware Fusion)
make base-arm64          # Stage 1: ISO → base VM
make build-arm64         # Stage 2: base → provisioned VM
make export-arm64        # Stage 3: export OVA
```

## Development Workflow

For iterative development against a running VM:

```bash
# First time: push SSH key to VM
make dev-setup DEV_VM_IP=10.1.50.124

# Deploy changes and reboot
make dev DEV_VM_IP=10.1.50.124
```

## Repository Structure

```
greymhatter/
├── ansible/                 # Ansible playbook and roles
│   ├── playbook.yml         # Main entry point
│   ├── group_vars/all.yml   # Pinned versions and variables
│   └── roles/               # base, docker, desktop, user, tools,
│                            # containers, courses, samba, verify
├── packer/                  # Packer templates
│   ├── greymhatter.pkr.hcl  # AMD64 (Proxmox)
│   ├── fusion/              # ARM64 (VMware Fusion)
│   └── http/ks.cfg          # Kickstart file
├── docs/                    # Documentation (MkDocs)
├── home/                    # User dotfiles
├── docker/                  # Docker Compose overrides
├── media/v2/                # Branding assets
├── tests/                   # Integration test suite
└── Makefile                 # Build targets
```

## Updating Deployed VMs

Students can update their VM without rebuilding:

```bash
greymhatter-update
```

This pulls the latest repository and re-runs the Ansible playbook.
