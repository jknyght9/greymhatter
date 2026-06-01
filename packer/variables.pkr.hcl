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
# Then set proxmox_iso_file to the path as Proxmox sees it (storage:iso/filename).
# Fusion/ESXi ISO references are declared in their own .pkr.hcl files since
# this variables.pkr.hcl is only loaded by the Proxmox build.

variable "fedora_version" {
  type    = string
  default = "42"
}

# --- Build identity (passed through by Makefile) ---
# build_date: YYYYMMDD stamped into VM name + filenames.
# build_sha: 7-char git short SHA, with -dirty suffix if working tree is modified.
# Both default to ad-hoc-safe values so direct `packer build` (without Make)
# still produces something valid.

variable "build_date" {
  type    = string
  default = ""
}

variable "build_sha" {
  type    = string
  default = "unknown"
}

variable "proxmox_iso_file" {
  type        = string
  description = "Proxmox path to the Fedora ISO (e.g., local:iso/Fedora-Server-netinst-x86_64-42-1.1.iso)"
  default     = ""
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

# --- MaxMind GeoIP (optional) ---

variable "maxmind_account_id" {
  type    = string
  default = ""
}

variable "maxmind_license_key" {
  type      = string
  default   = ""
  sensitive = true
}

# --- Docker Hub credentials (optional but recommended) ---
# Without auth, Docker Hub rate-limits anonymous pulls to 100 per 6h per
# source IP — easy to exhaust when iterating builds. Authenticated free-tier
# accounts get 200 per 6h per ACCOUNT. Use a personal access token instead
# of your password (Docker Hub → Account Settings → Personal access tokens).
# Token needs only "Public Repo Read" scope.

variable "docker_hub_username" {
  type    = string
  default = ""
}

variable "docker_hub_token" {
  type      = string
  default   = ""
  sensitive = true
}

# --- Local registry mirror (optional, preferred) ---
# Pull-through cache for Docker Hub. Eliminates rate limit + speeds builds.
# Format: "http://host:port" (HTTPS supported but typically HTTP on LAN).
# Setup: docker run -d -p 5050:5000 -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
#                   --restart=unless-stopped -v greymhatter-registry-data:/var/lib/registry \
#                   --name greymhatter-registry-mirror ghcr.io/distribution/distribution:3.0.0

variable "docker_registry_mirror" {
  type    = string
  default = ""
}

# --- GitHub PAT (optional but recommended) ---
# Anonymous GitHub API is 60 req/hr per IP — easy to exhaust when iterating
# (tools role makes 5 release-lookup calls per build). Authenticated PAT
# (classic, no scopes) gets 5000 req/hr.
# Get one at: github.com → Settings → Developer settings →
#             Personal access tokens (classic) → Generate new token

variable "github_token" {
  type      = string
  default   = ""
  sensitive = true
}
