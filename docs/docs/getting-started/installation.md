# Installation

## System Requirements

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disk | 40 GB | 80 GB |
| Hypervisor | VMware Workstation 17+ / Fusion 13+ | — |

## Download

Download the latest release artifacts for your architecture:

| Architecture | Download |
|---|---|
| AMD64 (Intel/AMD) | [greymhatter-f42-amd64-20260603.e9e97d0.ova](https://releases.greymhatter.com/v2.0.0/greymhatter-f42-amd64-20260603.e9e97d0.ova) |
| ARM64 (Apple Silicon) | [greymhatter-f42-arm64-20260603.e9e97d0.zip](https://releases.greymhatter.com/v2.0.0/greymhatter-f42-arm64-20260603.e9e97d0.zip) |
| Checksums | [SHA256SUMS](https://releases.greymhatter.com/v2.0.0/SHA256SUMS) |

Older releases are available under `https://releases.greymhatter.com/<tag>/`.

## Verify Download

Always verify the download integrity before importing:

=== "Linux / macOS"

    ```bash
    # Download the checksum manifest into the same directory as the artifact
    curl -O https://releases.greymhatter.com/v2.0.0/SHA256SUMS
    sha256sum --check --ignore-missing SHA256SUMS
    ```

=== "Windows (PowerShell)"

    ```powershell
    # Compute and compare against the published SHA256SUMS
    (Get-FileHash greymhatter-f42-amd64-*.ova -Algorithm SHA256).Hash
    Invoke-WebRequest https://releases.greymhatter.com/v2.0.0/SHA256SUMS -OutFile SHA256SUMS
    Get-Content SHA256SUMS
    ```

## Import into VMware

1. Unzip the downloaded file (if zipped)
2. Open VMware Workstation or Fusion
3. **File → Open** and select the `.ova` or `.ovf` file
4. Follow the import wizard
5. Boot the VM

## Fresh Install (Advanced)

If you prefer to install on a fresh Fedora 42 system:

```bash
# Fully update the system
sudo dnf upgrade --refresh -y

# Install Ansible
sudo dnf install -y ansible-core git

# Clone the repository
git clone https://github.com/jknyght9/greymhatter.git
cd greymhatter

# Run the Ansible playbook
sudo ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml
```

!!! note
    The fresh install process takes considerable time as it compiles several tools from source, downloads Docker images, and configures the desktop environment.
