# GreymHatter — VMware Fusion ARM64 Build (Staged)
#
# Stage 1: make build-arm64-base    Install Fedora from ISO → base VM (run once)
# Stage 2: make build-arm64         Snapshot base → run Ansible → export
#
# Runs natively on Mac — not containerized (needs Fusion hypervisor access)

variable "fusion_iso_url" {
  type        = string
  description = "HTTPS URL to the Fedora ARM64 server ISO; Packer downloads it during the build."
  default     = "https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/aarch64/iso/Fedora-Server-netinst-aarch64-42-1.1.iso"
}

variable "fusion_iso_checksum" {
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

variable "docker_hub_username" {
  type    = string
  default = ""
}

variable "docker_hub_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "docker_registry_mirror" {
  type    = string
  default = ""
}

variable "github_token" {
  type      = string
  default   = ""
  sensitive = true
}

# --- Build identity (passed through by Makefile) ---
variable "build_date" {
  type    = string
  default = ""
}

variable "build_sha" {
  type    = string
  default = "unknown"
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
  vm_name       = "greymhatter-f42-arm64-base"
  guest_os_type = "arm-fedora-64"
  version       = "20"

  iso_url      = var.fusion_iso_url
  iso_checksum = var.fusion_iso_checksum

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
  vm_name     = "greymhatter-f42-arm64-${var.build_date}.${var.build_sha}"
  source_path = "${path.root}/../../output/fusion-arm64-base/greymhatter-f42-arm64-base.vmx"

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

  # Inject project SSH public key for passwordless dev access — matches
  # the Proxmox base flow, lets `make smoke/verify/test DEV_VM_IP=<ip>`
  # work without sshpass fallback.
  provisioner "file" {
    source      = "${path.root}/../../crypto/greymhatter.pub"
    destination = "/home/hatter/.ssh/authorized_keys"
  }

  provisioner "shell" {
    inline = [
      "chown hatter:hatter /home/hatter/.ssh/authorized_keys",
      "chmod 600 /home/hatter/.ssh/authorized_keys",
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
      "ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --extra-vars 'greymhatter_repo_path=/tmp/greymhatter maxmind_account_id=${var.maxmind_account_id} maxmind_license_key=${var.maxmind_license_key} docker_hub_username=${var.docker_hub_username} docker_hub_token=${var.docker_hub_token} docker_registry_mirror=${var.docker_registry_mirror} github_token=${var.github_token} build_sha=${var.build_sha} build_date=${var.build_date}'",
    ]
  }

  provisioner "shell" {
    inline = [
      "dnf clean all",
      "rm -rf /tmp/greymhatter",
      "rm -rf /var/cache/dnf /var/cache/yum",

      "sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config",
      "passwd -d root",

      "mkdir -p /var/log/greymhatter",
      "DIAG=/var/log/greymhatter/cleanup-diagnostics.log",

      "echo '=== [1] Docker state BEFORE cleanup ===' | tee -a $DIAG",
      "echo 'images:' >> $DIAG; docker images 2>&1 | tee -a $DIAG",
      "echo 'imagedb_count:' $(ls /var/lib/docker/image/overlay2/imagedb/content/sha256/ 2>/dev/null | wc -l) | tee -a $DIAG",
      "echo 'layerdb_count:' $(ls /var/lib/docker/image/overlay2/layerdb/sha256/ 2>/dev/null | wc -l) | tee -a $DIAG",
      "cp /var/lib/docker/image/overlay2/repositories.json $DIAG.repos-before.json",

      "echo '=== [2] Stopping Docker ===' | tee -a $DIAG",
      "systemctl stop docker docker.socket containerd",
      "sleep 10",
      "sync",
      "echo 'imagedb_count after stop:' $(ls /var/lib/docker/image/overlay2/imagedb/content/sha256/ 2>/dev/null | wc -l) | tee -a $DIAG",
      "cp /var/lib/docker/image/overlay2/repositories.json $DIAG.repos-after-stop.json",

      "echo '=== [3] Running fstrim ===' | tee -a $DIAG",
      "fstrim -av 2>&1 | tee -a $DIAG || true",
      "sync",
      "echo 'imagedb_count after fstrim:' $(ls /var/lib/docker/image/overlay2/imagedb/content/sha256/ 2>/dev/null | wc -l) | tee -a $DIAG",
      "cp /var/lib/docker/image/overlay2/repositories.json $DIAG.repos-after-fstrim.json",

      "echo '=== [4] Post-cleanup image-count GATE ===' | tee -a $DIAG",
      "systemctl start docker",
      "for i in $(seq 1 30); do docker info --format '{{.ServerVersion}}' >/dev/null 2>&1 && break; sleep 2; done",
      "sleep 10",
      "echo '--- docker images dump ---' | tee -a $DIAG; docker images | tee -a $DIAG",
      "IMAGE_COUNT=$(docker images --quiet | sort -u | wc -l)",
      "echo \"Image count after fstrim: $IMAGE_COUNT\" | tee -a $DIAG",
      "if [ \"$IMAGE_COUNT\" -lt 7 ]; then echo 'FATAL: image count below threshold after cleanup; aborting build' | tee -a $DIAG; exit 1; fi",
      "systemctl stop docker docker.socket containerd",
      "sleep 5",
      "sync",

      "echo '=== [5] Truncating machine-id (last) ===' | tee -a $DIAG",
      "truncate -s 0 /etc/machine-id",
      "sync"
    ]
  }
}
