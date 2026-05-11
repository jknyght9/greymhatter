# Shell Functions

GreymHatter includes pre-configured fish shell functions for common DFIR workflows. All functions are defined in `~/.config/fish/config.fish`.

## Hayabusa (Windows Event Logs)

```bash
# Display metrics for a directory of EVTX files
hayabusa-metrics /path/to/evtx/

# Generate logon summary
hayabusa-summary /path/to/evtx/ output-name

# Generate full timeline (Timesketch-compatible CSV)
hayabusa-timeline /path/to/evtx/ output-name
```

Output is written to `/opt/share/hayabusa/`.

## Plaso / Log2timeline

All `log2timeline` functions require your working directory to be `/opt/share` and Timesketch to be running.

```bash
cd /opt/share

# Basic timeline creation
log2timeline output.plaso images/disk.E01

# Triage timeline (fast, common parsers)
log2timeline-triage output.plaso images/disk.E01

# Targeted parsers
log2timeline-targeted output.plaso images/disk.E01 "winevt,prefetch,mft"

# Full timeline (all partitions + VSS)
log2timeline-full output.plaso images/disk.E01

# Convert plaso to CSV
psort output.csv output.plaso
```

Output is written to `/opt/share/plaso/`.

## Forensic Image Mounting

```bash
# Mount an EWF/E01 image (default: /mnt/ewf)
mountewf evidence.E01
mountewf evidence.E01 /custom/mount

# Check partition layout
mmls /mnt/ewf/ewf1

# Mount a partition by byte offset (default: /mnt/evidence)
mountpartition 1048576
mountpartition 1048576 /mnt/ewf /custom/mount
```

## Container Management

```bash
# Start/stop services
starttimesketch    stoptimesketch
startyeti          stopyeti
startspiderfoot    stopspiderfoot

# Create a Timesketch sketch
timesketch-createsketch "Case-2026-001" "Investigation description"

# Import a timeline into Timesketch
timesketch-import /opt/share/hayabusa/timeline.csv
```

## Disk Management

```bash
# Check if the VM disk has unallocated space
disk-expand status

# Expand the root LV to fill available disk space
disk-expand grow
```

## System Updates

```bash
# Pull latest repo and re-run Ansible playbook
greymhatter-update

# Update course materials
course-update
```

## OSINT

```bash
# WHOIS lookup via Team Cymru
netioc 8.8.8.8
```

## Shell Aliases

| Alias | Command | Purpose |
|---|---|---|
| `ls` | `eza -lh --icons` | Enhanced file listing |
| `la` | `eza -lah --icons` | List all files |
| `lt` | `eza --tree` | Tree view |
| `cat` | `bat --paging=never` | Syntax-highlighted output |
| `grep` | `rg` | Fast ripgrep search |
| `df` | `duf` | Disk usage |
| `vim` | `nvim` | Neovim |
