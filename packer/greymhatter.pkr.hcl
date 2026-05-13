# GreymHatter Packer Template — Staged Build Pipeline
#
# Stage 1: make base         Install Fedora from ISO → Proxmox template (run once)
# Stage 2: make provision    Clone template → run Ansible (iterate fast)
# Stage 3: make export       Clean up clone → convert to template (future: OVA)
#
# All builds run inside a Docker container (see compose.yml).

packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# ===========================================================================
# Stage 1: Base Template (ISO install)
#
# Installs Fedora from ISO with Kickstart, installs base deps (ansible,
# qemu-guest-agent, SSH), converts to a Proxmox template.
# Run once — only rebuild when changing Fedora version or Kickstart.
# ===========================================================================

source "proxmox-iso" "fedora-base" {
  # Connection
  proxmox_url              = var.proxmox_url
  node                     = var.proxmox_node
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  insecure_skip_tls_verify = true

  # VM settings
  vm_name = "${var.vm_name}-base"
  vm_id   = var.base_vm_id

  # Hardware
  cores    = var.vm_cpus
  memory   = var.vm_memory
  cpu_type = "host"
  machine  = "q35"
  bios     = "seabios"
  os       = "l26"

  # Disk
  disks {
    disk_size    = var.vm_disk_size
    storage_pool = var.proxmox_storage_pool
    type         = "scsi"
    format       = "raw"
  }

  # Network
  network_adapters {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }

  # Boot ISO
  boot_iso {
    iso_file         = var.iso_file_amd64
    iso_storage_pool = var.proxmox_iso_storage
    unmount          = true
  }

  # Kickstart via CD-ROM (Fedora reads from OEMDRV label)
  additional_iso_files {
    cd_files         = ["${path.root}/http/ks.cfg"]
    cd_label         = "OEMDRV"
    iso_storage_pool = var.proxmox_iso_storage
    unmount          = true
    type             = "sata"
  }

  boot_command = [
    "<up><wait>",
    "e<wait>",
    "<down><down><end>",
    " inst.ks=cdrom:/ks.cfg",
    "<F10>"
  ]
  boot_wait = "10s"

  # SSH
  ssh_username = "root"
  ssh_password = var.ssh_password
  ssh_timeout  = "30m"
}

# ===========================================================================
# Stage 2: Provision (clone base → run Ansible)
#
# Clones the base template, copies repo files in, runs the Ansible playbook.
# This is the fast iteration loop — no ISO install, just clone + provision.
# ===========================================================================

source "proxmox-clone" "greymhatter" {
  # Connection
  proxmox_url              = var.proxmox_url
  node                     = var.proxmox_node
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  insecure_skip_tls_verify = true

  # Clone from base template
  clone_vm_id = var.base_vm_id
  vm_name     = "${var.vm_name}-dev"
  vm_id       = 0 # auto-assign

  # Hardware (inherit from template, but can override)
  cores    = var.vm_cpus
  memory   = var.vm_memory
  cpu_type = "host"

  # SSH
  ssh_username            = "root"
  ssh_password            = var.ssh_password
  ssh_timeout             = "30m"
  ssh_keep_alive_interval = "5s"
  ssh_handshake_attempts  = 100
}

# ===========================================================================
# Build: Stage 1 — Base template
# ===========================================================================

build {
  name = "base"

  sources = [
    "source.proxmox-iso.fedora-base",
  ]

  # Inject project SSH public key for passwordless dev access
  provisioner "file" {
    source      = "${path.root}/../crypto/greymhatter.pub"
    destination = "/home/hatter/.ssh/authorized_keys"
  }

  provisioner "shell" {
    inline = [
      "chown hatter:hatter /home/hatter/.ssh/authorized_keys",
      "chmod 600 /home/hatter/.ssh/authorized_keys",
      "echo 'Base template build complete'",
      "ansible --version",
      "systemctl is-enabled qemu-guest-agent",
      "systemctl is-enabled sshd"
    ]
  }
}

# ===========================================================================
# Build: Stage 2 — Provision (clone + Ansible)
# ===========================================================================

build {
  name = "greymhatter"

  sources = [
    "source.proxmox-clone.greymhatter",
  ]

  # --- Copy repo into VM ---
  provisioner "shell" {
    inline = ["mkdir -p /tmp/greymhatter"]
  }

  provisioner "file" {
    source      = "${path.root}/../ansible"
    destination = "/tmp/greymhatter/ansible"
  }

  provisioner "file" {
    source      = "${path.root}/../media"
    destination = "/tmp/greymhatter/media"
  }

  # --- Run Ansible playbook in stages to survive SSH reconnects ---
  provisioner "shell" {
    expect_disconnect = true
    inline = [
      "cd /tmp/greymhatter",
      "ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --extra-vars 'greymhatter_repo_path=/tmp/greymhatter' --tags base,docker,user",
    ]
  }

  provisioner "shell" {
    expect_disconnect = true
    pause_before      = "10s"
    inline = [
      "cd /tmp/greymhatter",
      "ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --extra-vars 'greymhatter_repo_path=/tmp/greymhatter' --tags tools",
    ]
  }

  provisioner "shell" {
    expect_disconnect = true
    pause_before      = "10s"
    inline = [
      "cd /tmp/greymhatter",
      "ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --extra-vars 'greymhatter_repo_path=/tmp/greymhatter maxmind_account_id=${var.maxmind_account_id} maxmind_license_key=${var.maxmind_license_key}' --tags containers",
    ]
  }

  provisioner "shell" {
    expect_disconnect = true
    pause_before      = "10s"
    inline = [
      "cd /tmp/greymhatter",
      "ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --extra-vars 'greymhatter_repo_path=/tmp/greymhatter' --tags desktop",
    ]
  }

  provisioner "shell" {
    expect_disconnect = true
    pause_before      = "10s"
    inline = [
      "cd /tmp/greymhatter",
      "ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --extra-vars 'greymhatter_repo_path=/tmp/greymhatter' --tags courses,samba,verify",
    ]
  }

  # --- Cleanup ---
  provisioner "shell" {
    inline = [
      "# Clean build artifacts (keep ansible-core for post-deploy updates)",
      "dnf clean all",
      "rm -rf /tmp/greymhatter",
      "rm -rf /var/cache/dnf /var/cache/yum",

      "# Lock down SSH",
      "sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config",
      "passwd -d root",

      "# Clear machine-id for template cloning",
      "truncate -s 0 /etc/machine-id",

      "# Zero free space for compression",
      "fstrim -av || true",
      "dd if=/dev/zero of=/EMPTY bs=1M 2>/dev/null || true",
      "rm -f /EMPTY",
      "sync"
    ]
  }
}
