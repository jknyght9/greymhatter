# GreymHatter — VMware Fusion ARM64 Build (Staged)
#
# Stage 1: make build-arm64-base    Install Fedora from ISO → base VM (run once)
# Stage 2: make build-arm64         Snapshot base → run Ansible → export
#
# Runs natively on Mac — not containerized (needs Fusion hypervisor access)

variable "iso_url_arm64" {
  type    = string
  default = "https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/aarch64/iso/Fedora-Server-netinst-aarch64-42-1.1.iso"
}

variable "iso_checksum_arm64" {
  type    = string
  default = "none"
}

variable "vm_cpus" {
  type    = number
  default = 4
}

variable "vm_memory" {
  type    = number
  default = 8192
}

variable "vm_disk_size" {
  type    = number
  default = 81920
}

variable "ssh_password" {
  type      = string
  default   = "packer"
  sensitive = true
}

variable "headless" {
  type    = bool
  default = false
}

variable "maxmind_account_id" {
  type    = string
  default = ""
}

variable "maxmind_license_key" {
  type      = string
  default   = ""
  sensitive = true
}

packer {
  required_plugins {
    vmware = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

# ===========================================================================
# Stage 1: Base VM (ISO install only)
# ===========================================================================

source "vmware-iso" "fedora-arm64-base" {
  vm_name          = "greymhatter-arm64-base"
  guest_os_type    = "arm-fedora-64"
  version          = "20"

  iso_url      = var.iso_url_arm64
  iso_checksum = var.iso_checksum_arm64

  cpus      = var.vm_cpus
  memory    = var.vm_memory
  disk_size = var.vm_disk_size

  disk_adapter_type    = "sata"
  network_adapter_type = "e1000e"

  output_directory = "${path.root}/../../output/fusion-arm64-base"

  cd_files = ["${path.root}/ks.cfg"]
  cd_label = "OEMDRV"

  boot_command = [
    "<up><wait>",
    "e<wait>",
    "<down><down><end>",
    " inst.ks=cdrom:/ks.cfg",
    "<F10>"
  ]
  boot_wait = "15s"

  ssh_username = "root"
  ssh_password = var.ssh_password
  ssh_timeout  = "30m"

  shutdown_command = "shutdown -P now"
  headless         = var.headless
}

# ===========================================================================
# Stage 2: Full build (provision with Ansible)
# Starts from the base VM output, runs Ansible, exports
# ===========================================================================

source "vmware-vmx" "greymhatter-arm64" {
  vm_name          = "greymhatter-arm64"
  source_path      = "${path.root}/../../output/fusion-arm64-base/greymhatter-arm64-base.vmx"

  output_directory = "${path.root}/../../output/fusion-arm64"

  ssh_username = "root"
  ssh_password = var.ssh_password
  ssh_timeout  = "10m"

  shutdown_command = "shutdown -P now"
  headless         = var.headless
}

# ===========================================================================
# Build: Stage 1 — Base VM
# ===========================================================================

build {
  name = "base"

  sources = [
    "source.vmware-iso.fedora-arm64-base",
  ]

  provisioner "shell" {
    inline = [
      "echo 'Base VM build complete'",
      "ansible --version",
      "systemctl is-enabled qemu-guest-agent || true",
      "systemctl is-enabled sshd"
    ]
  }
}

# ===========================================================================
# Build: Stage 2 — Provision with Ansible
# ===========================================================================

build {
  name = "greymhatter"

  sources = [
    "source.vmware-vmx.greymhatter-arm64",
  ]

  provisioner "shell" {
    inline = [
      "dnf install -y ansible-core git",
      "mkdir -p /tmp/greymhatter"
    ]
  }

  provisioner "file" {
    source      = "${path.root}/../../ansible"
    destination = "/tmp/greymhatter/ansible"
  }

  provisioner "file" {
    source      = "${path.root}/../../media"
    destination = "/tmp/greymhatter/media"
  }

  provisioner "shell" {
    expect_disconnect = true
    inline = [
      "cd /tmp/greymhatter",
      "ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --extra-vars 'greymhatter_repo_path=/tmp/greymhatter maxmind_account_id=${var.maxmind_account_id} maxmind_license_key=${var.maxmind_license_key}'",
    ]
  }

  provisioner "shell" {
    inline = [
      "dnf clean all",
      "rm -rf /tmp/greymhatter",
      "rm -rf /var/cache/dnf /var/cache/yum",

      "sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config",
      "passwd -d root",

      "truncate -s 0 /etc/machine-id",

      "fstrim -av || true",
      "dd if=/dev/zero of=/EMPTY bs=1M 2>/dev/null || true",
      "rm -f /EMPTY",
      "sync"
    ]
  }
}
