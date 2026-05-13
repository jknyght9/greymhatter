# GreymHatter Manual Testing Checklist

Run these checks on a deployed VM to verify all tools and services work correctly.
The automated test suite (`run-tests.sh`) covers memory, disk, and timeline analysis.
This checklist covers everything else.

**Credentials**: `hatter` / `H@tt3r123!`

---

## Desktop Environment

- [ ] System boots to LightDM login screen with greymhatter background
- [ ] Login with default credentials loads XFCE desktop
- [ ] Plank dock visible at bottom with application icons
- [ ] Conky system monitor displayed on desktop (CPU, RAM, disk, services)
- [ ] Wallpaper displays greymhatter branding

## Terminal & Shell

```bash
# Fish shell is default
echo $SHELL                          # /usr/bin/fish

# Starship prompt active
# (should show git branch, directory, exit code in prompt)

# Fastfetch on login (non-SSH only)
fastfetch                            # system info banner

# Aliases work
ls                                   # eza with icons
cat ~/.config/fish/config.fish       # bat with syntax highlighting
grep test /etc/hostname              # ripgrep
df                                   # duf
```

## CLI Tools

### Forensic Analysis

```bash
vol --help                           # Volatility 3
vol2 --help                          # Volatility 2 (Docker)
fls -V                               # Sleuthkit
mmls -V                              # Sleuthkit
bulk_extractor                       # should show usage
hayabusa --version                   # Hayabusa (in /opt/tools/)
```

### Malware Analysis

```bash
capa --version                       # capability detection
floss --version                      # obfuscated string extraction (AMD64 only)
yara --version                       # pattern matching
```

### Data & Intelligence

```bash
vt version                           # VirusTotal CLI
yq --version                         # YAML/JSON processor
imhex                                # GUI hex editor (launches window)
```

### Encryption

```bash
veracrypt --text --version           # VeraCrypt
bdemount --version                   # BitLocker mounting
fvdemount --version                  # FileVault mounting
```

### PowerShell & DFIR-PSTools

```bash
pwsh -c '$PSVersionTable'           # PowerShell 7+
pwsh -c 'Import-Module DFIR-PSTools; Get-Module DFIR-PSTools'
```

### ClamAV & Hashsets

```bash
clamscan --version                   # ClamAV scanner
ls /opt/clamav-hashbuilder/          # hashbuilder installed
ls /opt/hashsets/                    # hashset output directory
update-hashsets                      # restart hashbuilder to refresh
```

## Fish Shell Helper Functions

### Forensic Image Mounting

```bash
mountewf -h                         # EWF mount helper
mountpartition -h                    # partition mount helper
```

### Hayabusa Helpers

```bash
hayabusa-metrics -h                  # event log metrics
hayabusa-summary -h                  # logon summary
hayabusa-timeline -h                 # timeline generation
```

### Log2timeline Helpers

```bash
# All require working directory /opt/share and Timesketch running
log2timeline -h
log2timeline-triage -h
log2timeline-targeted -h
log2timeline-full -h
psort -h
```

### Container Management

```bash
starttimesketch                      # starts all Timesketch containers
stoptimesketch                       # stops Timesketch

startyeti                            # starts Yeti (AMD64 only)
stopyeti

startspiderfoot                      # starts SpiderFoot
stopspiderfoot
```

### Timesketch Helpers

```bash
timesketch-createsketch "Test" "Description"   # create sketch via API
timesketch-import -h                            # import timeline
```

### System

```bash
disk-expand status                   # show disk/LV/filesystem sizes
greymhatter-update                   # pull repo + run Ansible
course-update                        # update course materials
netioc 8.8.8.8                       # WHOIS lookup via Cymru
update-hashsets                      # refresh ClamAV hashsets
```

## Container Services

### Auto-start (verify running after boot)

```bash
docker ps                            # should show homepage, cyberchef, courses, clamav-hashbuilder
curl -so /dev/null -w '%{http_code}' http://localhost:3000    # Homepage: 200
curl -so /dev/null -w '%{http_code}' http://localhost:8080    # CyberChef: 200
curl -so /dev/null -w '%{http_code}' http://localhost:8000    # Courses: 200
```

### Manual-start

```bash
# Timesketch
starttimesketch
curl -kso /dev/null -w '%{http_code}' https://localhost       # 200 or 302
# Login at https://localhost with hatter / H@tt3r123!
# Verify: create sketch, import timeline, view events
stoptimesketch
# Restart and verify user persists
starttimesketch
# Login should work without recreating user
stoptimesketch

# SpiderFoot
startspiderfoot
curl -so /dev/null -w '%{http_code}' http://localhost:5001    # 200
stopspiderfoot

# Yeti (AMD64 only)
startyeti
curl -kso /dev/null -w '%{http_code}' https://localhost:8888  # 200 or 302
stopyeti
```

## Samba Share

```bash
# Verify service is running
sudo systemctl status smb

# From Windows: \\<VM_IP>\share
# From Linux:   sudo mount -t cifs //<VM_IP>/share /mnt -o username=hatter
# From macOS:   Finder → Cmd+K → smb://<VM_IP>/share
```

## Network & Security

```bash
# Firewall
sudo firewall-cmd --state                     # running
sudo firewall-cmd --list-services             # ssh, samba, https
sudo firewall-cmd --list-ports                # 3000, 5001, 8000, 8080, 8888, etc.

# SSH
sudo systemctl status sshd                    # active

# SELinux
getenforce                                    # Permissive
```

## System

```bash
# Hostname
hostname                                      # greymhatter

# Timezone
timedatectl | grep "Time zone"                # America/Chicago

# Disk / LVM
disk-expand status                            # /dev/fedora/root, XFS
df -Th /                                      # xfs filesystem

# sysctl (required for OpenSearch)
sysctl vm.max_map_count                       # 262144

# Docker
docker --version
docker compose version
docker ps                                     # auto-start containers running
```

## Browser Verification

Open Firefox and check each service:

- [ ] `http://localhost:3000` — Homepage dashboard with links
- [ ] `http://localhost:8080` — CyberChef (test a Base64 encode/decode)
- [ ] `http://localhost:8000` — Course materials (if configured)
- [ ] `https://localhost` — Timesketch login (after `starttimesketch`)

## Architecture-Specific Notes

### AMD64 Only
- FLOSS binary download (ARM64 uses pip)
- vt-cli binary download (ARM64 compiles from Go source)
- Yeti (requires SSE4.2/AVX instructions)
- CPU type must be `host` (not `kvm64`) for OpenSearch x86-64-v2

### ARM64
- Timesketch image built from source during provisioning
- Volatility 2 Docker image built natively
- Sleuthkit + dependencies compiled from source via Docker builder
