# Changelog

## v2.0.0 — 2026-06-08

First tagged release of the modernized Ansible + Packer pipeline. Replaces the v1.0.0 bash-script installer with reproducible image builds and adds ARM64 parity alongside AMD64.

Downloads: <https://releases.greymhatter.com/v2.0.0/>

### Changed
- Migrated provisioning from bash scripts to Ansible roles (9 roles)
- Replaced GNOME desktop with XFCE (Qogir theme, Plank dock, Conky)
- Replaced Alacritty terminal with Ghostty
- Switched from ad-hoc Docker networks to shared `greymhatter` network
- Only lightweight containers (Homepage, CyberChef, Courses) auto-start on boot
- Removed predefined mount points — students create their own
- Packer builds run natively (not containerized) for both architectures

### Added
- Automated VM builds via Packer (Proxmox for AMD64, VMware Fusion for ARM64)
- Volatility 2 Docker container with ARM64 support
- Timesketch ARM64 support (built from source during provisioning)
- `disk-expand` fish function for LVM expansion after VM disk resize
- `timesketch-createsketch` fish function for sketch creation via API
- Integration test suite with memory, disk, and timeline tests
- Manual testing checklist
- DFIR-PSTools PowerShell module
- clamav-hashbuilder (ClamAV to Autopsy hashset builder)
- ImHex GUI hex editor
- yq YAML/JSON processor
- Course material delivery via MkDocs container
- Docker daemon log rotation and resource optimization
- Project documentation site (MkDocs)
- ARM64 support for capa, vt-cli (compiled from Go source)
- Pre-built Volatility 3 symbol cache during provisioning
- LightDM + slick-greeter login screen with greymhatter branding

### Fixed
- ARM64 architecture support expanded across full tool matrix
- Docker log rotation prevents disk exhaustion on teaching VMs
- Sleuthkit compiled from source with libvmdk/libvhdi support
- SpiderFoot Dockerfile patched for Alpine 3.20 (3.12 EOL)
- Volatility 2 Dockerfile uses archive.debian.org (Buster EOL)
- CyberChef port updated to 8080 (upstream change)
- Timesketch nginx.conf mounted correctly for SSL
