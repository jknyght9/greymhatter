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

The base templates ship with the project SSH key (`crypto/greymhatter.pub`)
pre-injected, so `make dev`/`make test`/`make verify` can SSH into a cloned
VM without manual setup.

## Development Workflow

For iterative development against a running VM:

```bash
# Deploy current repo state to a running VM (SCP + Ansible + reboot)
make dev DEV_VM_IP=10.1.50.124

# Fast smoke test (~60s) — confirms expected containers are up
make smoke DEV_VM_IP=10.1.50.124

# Manifest-driven verify (~30s, skips startable-service deep checks)
make verify DEV_VM_IP=10.1.50.124

# Full verify including Timesketch/Yeti/SpiderFoot deep checks (~3-4 min)
make verify-deep DEV_VM_IP=10.1.50.124

# DFIR tool integration tests (vol2/vol3, log2timeline, Timesketch import)
make test DEV_VM_IP=10.1.50.124
```

## Repository Structure

```
greymhatter/
├── ansible/                 # Ansible playbook and roles
│   ├── playbook.yml         # Main entry point
│   ├── group_vars/all/defaults.yml   # Pinned versions and variables
│   └── roles/               # base, docker, desktop, user, tools,
│                            # containers, courses, samba, verify
├── packer/                  # Packer templates
│   ├── greymhatter.pkr.hcl  # AMD64 (Proxmox)
│   ├── fusion/              # ARM64 (VMware Fusion)
│   └── http/ks.cfg          # Kickstart file
├── docs/                    # Documentation (MkDocs)
├── crypto/                  # Project SSH keys (gitignored)
├── media/v2/                # Branding assets
├── scripts/                 # Build / dev helper scripts
├── tests/                   # Integration test suite
└── Makefile                 # Build targets
```

## Updating Deployed VMs

Students can update their VM without rebuilding:

```bash
greymhatter-update
```

This pulls the latest repository and re-runs the Ansible playbook.
