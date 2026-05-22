# GreymHatter — ESXi AMD64 Build (Staged)
#
# Stage 1: make base-esxi    Install Fedora from ISO → ESXi base template (run once)
# Stage 2: make build-esxi   Clone base → run Ansible → convert to template
# Stage 3: make export-esxi  ovftool pulls the template off ESXi as an .ova
#
# Connection is via vsphere-iso/vsphere-clone against an ESXi host (no vCenter).
# The host is typically reached through an SSH tunnel — esx_url is the local
# end of that tunnel (e.g. https://127.0.0.1:4004).

# --- Connection ---

variable "esx_url" {
  type        = string
  description = "ESXi URL incl. scheme + port (e.g. https://127.0.0.1:4004 via SSH tunnel)"
}

variable "esx_host" {
  type        = string
  description = "Hostname/IP of the ESXi host as it identifies itself (e.g. esxi01.local or 10.1.50.220). Required by the vsphere plugin even for standalone ESXi."
}

variable "esx_username" {
  type    = string
  default = "root"
}

variable "esx_password" {
  type      = string
  sensitive = true
}

variable "esx_storage" {
  type        = string
  description = "Datastore name as ESXi sees it (e.g. SAS-Storage-01)"
}

variable "esx_vm_network" {
  type        = string
  description = "Network/port group name as ESXi sees it (e.g. VM Network)"
}

variable "esx_iso_file" {
  type        = string
  description = "Path to Fedora ISO on an ESXi datastore: [datastore] path/file.iso"
}

# --- VM specs ---

variable "fedora_version" {
  type    = string
  default = "42"
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
  type        = string
  default     = "80G"
  description = "Disk size with G suffix (matches the shared pkrvars convention)"
}

variable "ssh_password" {
  type      = string
  default   = "packer"
  sensitive = true
}

# --- Maxmind (passed through to Ansible) ---

variable "maxmind_account_id" {
  type    = string
  default = ""
}

variable "maxmind_license_key" {
  type      = string
  default   = ""
  sensitive = true
}

# --- Docker Hub creds + registry mirror (passed through to Ansible) ---

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

variable "docker_mtu" {
  type    = string
  default = ""
}

# --- IP of the cloned VM (populated by scripts/clone-esxi.sh via Makefile) ---

variable "build_vm_ip" {
  type        = string
  description = "IP of the VM to provision. Set by scripts/clone-esxi.sh and passed in by `make build-esxi`. Required for the `greymhatter` build."
  default     = ""
}

packer {
  required_plugins {
    vsphere = {
      version = ">= 1.4.0"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

# Strip scheme so the plugin can build its own SDK URL
locals {
  vcenter_endpoint = trimprefix(trimprefix(var.esx_url, "https://"), "http://")
  base_vm_name     = "greymhatter-f${var.fedora_version}-esxi-base"
  final_vm_name    = "greymhatter-f${var.fedora_version}-esxi-${formatdate("YYYYMMDD", timestamp())}"
}

# ===========================================================================
# Stage 1: Base VM (ISO install only) — `make base-esxi`
# Builds a clean Fedora install with kickstart, leaves it powered off.
# Re-runs of build-esxi clone from this VM rather than re-installing.
# ===========================================================================

source "vsphere-iso" "fedora-esxi-base" {
  vcenter_server      = local.vcenter_endpoint
  username            = var.esx_username
  password            = var.esx_password
  insecure_connection = true
  host                = var.esx_host

  vm_name       = local.base_vm_name
  guest_os_type = "fedora64Guest"
  notes         = "GreymHatter base (built by Packer) — clone source for build-esxi"

  CPUs            = var.vm_cpus
  RAM             = var.vm_memory
  RAM_reserve_all = false
  firmware        = "efi"
  video_ram       = 16384 # 16 MB SVGA — default 4 MB caps the guest at 1280x768

  datastore = var.esx_storage

  disk_controller_type = ["lsilogic-sas"]
  storage {
    disk_size             = parseint(replace(var.vm_disk_size, "G", ""), 10) * 1024
    disk_thin_provisioned = true
  }

  network_adapters {
    network      = var.esx_vm_network
    network_card = "vmxnet3"
  }

  # Disk first, fallback to CD. On the empty first-install boot EFI falls
  # through to CD-ROM (Fedora installer loads). After install completes,
  # the populated disk wins — no install loop. Earlier attempts had this
  # reversed plus BIOS firmware, which caused both "OS not found" (BIOS
  # didn't fall through) and the install loop (cdrom always wins post-install).
  boot_order = "disk,cdrom"

  iso_paths = [var.esx_iso_file]

  # Kickstart attached as a second CD labelled OEMDRV so anaconda picks it up
  # without us needing to run an HTTP server reachable from the ESXi VM
  # (which would be awkward through the SSH tunnel).
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

  shutdown_command    = "shutdown -P now"
  convert_to_template = false # standalone ESXi (no vCenter) lacks the MarkAsTemplate API. vsphere-clone clones from a regular VM just fine.
}

# ===========================================================================
# Stage 2: Provision (Ansible against a pre-cloned VM) — `make build-esxi`
#
# Standalone ESXi (no vCenter) doesn't expose the Clone API that
# Packer's vsphere-clone source uses, so we clone the base VM externally
# via ovftool (scripts/clone-esxi.sh) and use Packer's `null` source to
# run Ansible over SSH against the resulting IP.
#
# The clone script handles: ovftool clone, power on, vmtools IP polling.
# Packer here only owns the provisioning + cleanup steps.
# ===========================================================================

source "null" "greymhatter-esxi-clone" {
  ssh_host     = var.build_vm_ip
  ssh_username = "root"
  ssh_password = var.ssh_password
  ssh_timeout  = "10m"
}

# ===========================================================================
# Build: Stage 1 — Base VM
# ===========================================================================

build {
  name = "base"

  sources = [
    "source.vsphere-iso.fedora-esxi-base",
  ]

  # Base VM is left at a clean Fedora install with ansible-core ready to go.
  # No provisioning here — that's stage 2's job. The post-install script in
  # ks.cfg has already installed ansible-core + git.
  provisioner "shell" {
    inline = [
      "echo 'Base VM ready.'",
      "ansible --version",
      "systemctl is-enabled sshd",
      "systemctl is-enabled vmtoolsd"
    ]
  }
}

# ===========================================================================
# Build: Stage 2 — Provision
# ===========================================================================

build {
  name = "greymhatter"

  sources = [
    "source.null.greymhatter-esxi-clone",
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
      "ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --extra-vars 'greymhatter_repo_path=/tmp/greymhatter maxmind_account_id=${var.maxmind_account_id} maxmind_license_key=${var.maxmind_license_key} docker_hub_username=${var.docker_hub_username} docker_hub_token=${var.docker_hub_token} docker_registry_mirror=${var.docker_registry_mirror} github_token=${var.github_token} docker_mtu=${var.docker_mtu}'",
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
      "docker images 2>&1 | tee -a $DIAG",
      "systemctl stop docker docker.socket containerd 2>/dev/null || true",
      "sleep 5",
      "sync",
      "fstrim -av 2>&1 | tee -a $DIAG || true",
      "sync",
      "echo '=== [2] Post-cleanup image-count GATE ===' | tee -a $DIAG",
      "systemctl start docker",
      "for i in $(seq 1 30); do docker info >/dev/null 2>&1 && break; sleep 2; done",
      "sleep 10",
      "echo '--- docker images dump ---' | tee -a $DIAG; docker images | tee -a $DIAG",
      "IMAGE_COUNT=$(docker images --quiet | sort -u | wc -l)",
      "echo \"Image count after fstrim: $IMAGE_COUNT\" | tee -a $DIAG",
      "if [ \"$IMAGE_COUNT\" -lt 7 ]; then echo 'FATAL: image count below threshold after cleanup; aborting build' | tee -a $DIAG; exit 1; fi",
      "systemctl stop docker docker.socket containerd",
      "sleep 5",
      "sync",
      "truncate -s 0 /etc/machine-id",
      "sync"
    ]
  }

  # null source has no managed VM lifecycle, so we explicitly shut down at
  # the end. nohup + & detaches so the SSH disconnect doesn't fail the task.
  provisioner "shell" {
    inline = [
      "echo 'Shutting down VM (nohup so SSH can disconnect cleanly)'",
      "nohup sh -c 'sleep 2 && shutdown -h now' >/dev/null 2>&1 &",
      "sleep 1"
    ]
  }
}
