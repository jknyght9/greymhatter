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
  vm_name = "greymhatter-f${var.fedora_version}-amd64-base"
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

  # Clone task timeout — default 60s is too short on a busy cluster;
  # qmclone of a >2GB template can take longer if storage is contended.
  task_timeout = "10m"

  # Clone from base template
  clone_vm_id = var.base_vm_id
  vm_name     = "greymhatter-f${var.fedora_version}-amd64-${formatdate("YYYYMMDD", timestamp())}"
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
  # docker_hub creds passed to chunk 1 so the docker role can authenticate
  # before any subsequent chunk pulls images (avoids Docker Hub rate limit).
  provisioner "shell" {
    expect_disconnect = true
    inline = [
      "cd /tmp/greymhatter",
      "ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --extra-vars 'greymhatter_repo_path=/tmp/greymhatter docker_hub_username=${var.docker_hub_username} docker_hub_token=${var.docker_hub_token} docker_registry_mirror=${var.docker_registry_mirror}' --tags base,docker,user",
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
      "ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --extra-vars 'greymhatter_repo_path=/tmp/greymhatter' --tags courses,samba",
    ]
  }

  # --- Verify (build-aborting gate) ---
  # Runs after all roles. Manifest-driven assertions: any failure aborts the
  # build before cleanup, so we never seal a template with missing images,
  # broken services, or schema-less databases. No expect_disconnect: verify
  # must NOT disconnect SSH, and a failure here is fatal by design.
  provisioner "shell" {
    pause_before = "30s"
    inline = [
      "cd /tmp/greymhatter",
      "ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --extra-vars 'greymhatter_repo_path=/tmp/greymhatter' --tags verify -v",
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

      "mkdir -p /var/log/greymhatter",
      "DIAG=/var/log/greymhatter/cleanup-diagnostics.log",

      "echo '=== [1] Docker state BEFORE cleanup ===' | tee -a $DIAG",
      "echo 'images:' >> $DIAG; docker images --format '{{.Repository}}:{{.Tag}}' 2>&1 | tee -a $DIAG",
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
      "echo '--- docker images dump ---' | tee -a $DIAG; docker images --format '{{.Repository}}:{{.Tag}}' | sort | tee -a $DIAG",
      "IMAGE_COUNT=$(docker images --format '{{.Repository}}' | grep -v '^<none>$' | sort -u | wc -l)",
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
