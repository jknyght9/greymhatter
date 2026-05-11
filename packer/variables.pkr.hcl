# GreymHatter Packer Variables

# --- Proxmox Connection ---

variable "proxmox_url" {
  type        = string
  description = "Proxmox API URL (e.g., https://192.168.1.100:8006/api2/json)"
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name"
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox API username (e.g., root@pam or packer@pve!packer-token)"
}

variable "proxmox_token" {
  type        = string
  description = "Proxmox API token (alternative to password)"
  sensitive   = true
  default     = ""
}

# --- Proxmox Storage ---

variable "proxmox_storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "proxmox_iso_storage" {
  type    = string
  default = "local"
}

variable "proxmox_bridge" {
  type    = string
  default = "vmbr0"
}

# --- Fedora ISO ---
# Pre-download the ISO to your Proxmox node's ISO storage:
#   wget -P /var/lib/vz/template/iso/ <fedora-iso-url>
# Then set iso_file_amd64 to the path as Proxmox sees it (storage:type/filename).

variable "fedora_version" {
  type    = string
  default = "42"
}

variable "iso_file_amd64" {
  type        = string
  description = "Proxmox path to the Fedora ISO (e.g., local:iso/Fedora-Server-netinst-x86_64-42-1.1.iso)"
  default     = ""
}

variable "iso_url_amd64" {
  type    = string
  default = "https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/iso/Fedora-Server-netinst-x86_64-42-1.1.iso"
}

variable "iso_checksum_amd64" {
  type    = string
  default = "none"
}

variable "iso_file_arm64" {
  type        = string
  description = "Proxmox path to the ARM64 Fedora ISO (e.g., local:iso/Fedora-Server-netinst-aarch64-42-1.1.iso)"
  default     = ""
}

variable "iso_url_arm64" {
  type    = string
  default = "https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/aarch64/iso/Fedora-Server-netinst-aarch64-42-1.1.iso"
}

variable "iso_checksum_arm64" {
  type    = string
  default = "none"
}

# --- VM Specs ---

variable "vm_name" {
  type    = string
  default = "greymhatter"
}

variable "base_vm_id" {
  type        = number
  description = "VM ID for the base Fedora template (Stage 1). Must be fixed so Stage 2 can clone it."
  default     = 9000
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
  type    = string
  default = "80G"
}

variable "headless" {
  type    = bool
  default = true
}

# --- SSH (used by Packer to connect after Kickstart) ---

variable "ssh_password" {
  type      = string
  default   = "packer"
  sensitive = true
}
