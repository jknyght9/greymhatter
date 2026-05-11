# Installation

## System Requirements

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disk | 40 GB | 80 GB |
| Hypervisor | VMware Workstation 17+ / Fusion 13+ | — |

## Download

Download the latest OVA for your architecture:

| Architecture | Download | SHA256 |
|---|---|---|
| AMD64 (Intel/AMD) | Coming soon | — |
| ARM64 (Apple Silicon) | Coming soon | — |

## Verify Download

Always verify the download integrity before importing:

=== "Linux / macOS"

    ```bash
    sha256sum -c greymhatter*.sha256
    ```

=== "Windows (PowerShell)"

    ```powershell
    Get-FileHash greymhatter*.zip
    Get-Content greymhatter*.sha256
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
