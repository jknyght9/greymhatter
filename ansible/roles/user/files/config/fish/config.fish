# Set greeting — show ARM64 note on first shell if applicable
if test (uname -m) = "aarch64"
  set -g -x fish_greeting 'NOTE: Some x86_64-only tools are unavailable on ARM64. See /opt/greymhatter/arch-notes.txt'
else
  set -g -x fish_greeting ''
end

# Add to environment
fish_add_path ~/.local/bin/
fish_add_path /opt/tools/

# Aliases: File Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias c='clear'
alias ls='eza -lh --icons --group --group-directories-first --time-style long-iso'
alias la='eza -lah --icons --group --group-directories-first --time-style long-iso'
alias lt='eza --tree'
alias lat='eza -lah --icons --group --group-directories-first --time-style long-iso --tree'

# Aliases: File manipulation
alias cat='bat --paging=never'
alias catp='bat -p --paging=never'
alias grep='rg'

# Aliases: System
alias df='duf'
alias disku='du -sh * | sort -h'
alias myip='curl https://ifconfig.co'
alias myipj='curl https://ifconfig.co/json'
alias reload='source ~/.config/fish/config.fish'
alias vim=nvim

# --- Helper: check if a container is running ---
function _container_running
  docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^$argv[1]\$"
end

# --- Helper: check if a service directory exists ---
function _service_dir
  if not test -d $argv[1]
    printf "Service not installed at %s\n" $argv[1]
    return 1
  end
  return 0
end

# --- Hayabusa (Windows Event Log Analysis) ---

function hayabusa-metrics
  if test (count $argv) -eq 0; or test "$argv[1]" = "-h"
    printf "Usage: hayabusa-metrics DIRECTORYOFEVTXFILES\n\n"
    return 0
  end
  if not test -x /opt/tools/hayabusa/hayabusa
    printf "Hayabusa is not installed.\n"
    return 1
  end
  /opt/tools/hayabusa/hayabusa computer-metrics -d $argv[1]
  /opt/tools/hayabusa/hayabusa eid-metrics -d $argv[1]
end

function hayabusa-summary
  if test (count $argv) -lt 2; or test "$argv[1]" = "-h"
    printf "Usage: hayabusa-summary DIRECTORYOFEVTXFILES OUTPUTFILENAME\n\n"
    return 0
  end
  if not test -x /opt/tools/hayabusa/hayabusa
    printf "Hayabusa is not installed.\n"
    return 1
  end
  printf "Running command: hayabusa logon-summary -d $argv[1] -o /opt/share/hayabusa/$argv[2]-logonsummary\n\n"
  /opt/tools/hayabusa/hayabusa logon-summary -d $argv[1] -o /opt/share/hayabusa/$argv[2]-logonsummary
end

function hayabusa-timeline
  if test (count $argv) -lt 2; or test "$argv[1]" = "-h"
    printf "Usage: hayabusa-timeline DIRECTORYOFEVTXFILES OUTPUTFILENAME\n\n"
    return 0
  end
  if not test -x /opt/tools/hayabusa/hayabusa
    printf "Hayabusa is not installed.\n"
    return 1
  end
  printf "Running command: hayabusa csv-timeline -d $argv[1] --RFC-3339 -p timesketch-verbose -U -T -G /opt/maxmind-geoipupdate/geoip_data/ -o /opt/share/hayabusa/$argv[2]-hayabusa-timeline.csv --sort\n\n"
  /opt/tools/hayabusa/hayabusa csv-timeline -d $argv[1] --RFC-3339 -p timesketch-verbose -U -T -G /opt/maxmind-geoipupdate/geoip_data/ -o /opt/share/hayabusa/$argv[2]-hayabusa-timeline.csv --sort
end

# --- Log2timeline (Plaso via Timesketch container) ---

function log2timeline
  if test (count $argv) -eq 0; or test "$argv[1]" = "-h"
    printf "Usage: log2timeline TIMELINENAME.plaso IMAGEORDIRECTORYPATH ADDITIONALARGUMENTS\n\n"
    printf "Outputting to the /opt/share/plaso directory.\n"
    return 0
  end
  if not _container_running timesketch-worker
    printf "Timesketch is not running. Starting...\n"
    starttimesketch
    sleep 10
    if not _container_running timesketch-worker
      printf "Failed to start Timesketch\n"
      return 1
    end
  end
  if test (pwd) = "/opt/share"
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] $argv[3..-1]
  else
    printf "Your evidence and current directory must be '/opt/share'\n"
  end
end

function log2timeline-triage
  if test (count $argv) -lt 2; or test "$argv[1]" = "-h"
    printf "Usage: log2timeline-triage TIMELINENAME.plaso IMAGEORDIRECTORYPATH\n\n"
    printf "Outputting to the /opt/share/plaso directory.\n"
    return 0
  end
  if not _container_running timesketch-worker
    printf "Timesketch is not running. Starting...\n"
    starttimesketch
    sleep 10
    if not _container_running timesketch-worker
      printf "Failed to start Timesketch\n"
      return 1
    end
  end
  if test (pwd) = "/opt/share"
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2]
  else
    printf "Your evidence and current directory must be '/opt/share'\n"
  end
end

function log2timeline-targeted
  if test (count $argv) -lt 3; or test "$argv[1]" = "-h"
    printf "Usage: log2timeline-targeted TIMELINENAME.plaso IMAGEORDIRECTORYPATH \"PARSERS,COMMA,SEPARATED\"\n\n"
    printf "Outputting to the /opt/share/plaso directory.\n"
    return 0
  end
  if not _container_running timesketch-worker
    printf "Timesketch is not running. Starting...\n"
    starttimesketch
    sleep 10
    if not _container_running timesketch-worker
      printf "Failed to start Timesketch\n"
      return 1
    end
  end
  if test (pwd) = "/opt/share"
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] --parsers=$argv[3] --partitions "all"
  else
    printf "Your evidence and current directory must be '/opt/share'\n"
  end
end

function log2timeline-full
  if test (count $argv) -lt 2; or test "$argv[1]" = "-h"
    printf "Usage: log2timeline-full TIMELINENAME.plaso IMAGEORDIRECTORYPATH\n\n"
    printf "Outputting to the /opt/share/plaso directory.\n"
    return 0
  end
  if not _container_running timesketch-worker
    printf "Timesketch is not running. Starting...\n"
    starttimesketch
    sleep 10
    if not _container_running timesketch-worker
      printf "Failed to start Timesketch\n"
      return 1
    end
  end
  if test (pwd) = "/opt/share"
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] --partitions "all" --vss_stores "all"
  else
    printf "Your evidence and current directory must be '/opt/share'\n"
  end
end

# --- Forensic Image Mounting ---

function mountewf
  if test (count $argv) -eq 0; or test "$argv[1]" = "-h"
    printf "Usage: mountewf IMAGEFILE [MOUNTPOINT]\n"
    printf "  Default mount point: /mnt/ewf\n\n"
    return 0
  end
  set -l mountpoint /mnt/ewf
  if test (count $argv) -ge 2
    set mountpoint $argv[2]
  end
  sudo mkdir -p $mountpoint
  sudo ewfmount $argv[1] $mountpoint
  printf "Mounted to %s\n" $mountpoint
  printf "Now run 'mmls %s/ewf1' and get the start offset of the target partition and multiply it with the # of sectors (e.g. X * 512)\n" $mountpoint
end

function mountpartition
  if test (count $argv) -lt 2; or test "$argv[1]" = "-h"
    printf "Usage: mountpartition OFFSET EWFMOUNTPOINT [MOUNTPOINT]\n"
    printf "  OFFSET: byte offset from mmls (sector * 512)\n"
    printf "  EWFMOUNTPOINT: path to ewf mount (e.g. /mnt/ewf)\n"
    printf "  MOUNTPOINT: optional destination (default: /mnt/evidence)\n\n"
    return 0
  end
  set -l offset $argv[1]
  set -l ewfpath $argv[2]/ewf1
  set -l mountpoint /mnt/evidence
  if test (count $argv) -ge 3
    set mountpoint $argv[3]
  end
  sudo mkdir -p $mountpoint
  sudo mount -t ntfs-3g -o loop,ro,show_sys_files,stream_interface=windows,offset=$offset $ewfpath $mountpoint
  printf "Partition mounted to %s\n" $mountpoint
end

# --- OSINT ---

function netioc
  whois -h whois.cymru.com " -v $argv"
end

# --- Plaso Timeline Processing ---

function psort
  if test (count $argv) -lt 2; or test "$argv[1]" = "-h"
    printf "Usage: psort OUTPUTFILENAME.csv TIMELINENAME.plaso\n\n"
    printf "Timelines must be in the /opt/share/plaso directory.\n"
    printf "Outputting to the /opt/share/plaso directory.\n"
    return 0
  end
  if not _container_running timesketch-worker
    printf "Timesketch is not running. Starting...\n"
    starttimesketch
    sleep 10
    if not _container_running timesketch-worker
      printf "Failed to start Timesketch\n"
      return 1
    end
  end
  if test (pwd) = "/opt/share"
    sudo docker exec -i timesketch-worker psort.py -o l2tcsv -w /share/plaso/$argv[1] /share/plaso/$argv[2]
  else
    printf "Your current directory must be '/opt/share'\n"
  end
end

# --- Container Management ---

function startspiderfoot
  _service_dir /opt/spiderfoot; or return 1
  cd /opt/spiderfoot && docker compose up -d
end

function starttimesketch
  _service_dir /opt/timesketch; or return 1
  cd /opt/timesketch && docker compose --env-file config.env up -d --pull never
end

function startyeti
  _service_dir /opt/yeti-docker/prod; or return 1
  cd /opt/yeti-docker/prod && docker compose up -d
end

function stopspiderfoot
  _service_dir /opt/spiderfoot; or return 1
  cd /opt/spiderfoot && docker compose down
end

function stoptimesketch
  _service_dir /opt/timesketch; or return 1
  cd /opt/timesketch && docker compose --env-file config.env down
end

function stopyeti
  _service_dir /opt/yeti-docker/prod; or return 1
  cd /opt/yeti-docker/prod && docker compose down
end

# --- Timesketch Helpers ---

function timesketch-createsketch
  if test (count $argv) -eq 0; or test "$argv[1]" = "-h"
    printf "Usage: timesketch-createsketch SKETCHNAME [DESCRIPTION]\n\n"
    printf "Creates a new Timesketch sketch and prints the sketch ID.\n"
    return 0
  end
  if not _container_running timesketch-web
    printf "Timesketch is not running. Start it with: starttimesketch\n"
    return 1
  end
  set -l name "$argv[1]"
  set -l desc ""
  if test (count $argv) -ge 2
    set desc "$argv[2]"
  end
  # Authenticate: get CSRF token, login, then create sketch
  set -l csrf (curl -sk -c /tmp/ts-cookies http://localhost/login/ 2>/dev/null \
    | sed -n 's/.*csrf_token.*value="\([^"]*\)".*/\1/p')
  curl -sk -c /tmp/ts-cookies -b /tmp/ts-cookies -X POST http://localhost/login/ \
    -d "username=hatter&password=H@tt3r123!&csrf_token=$csrf" \
    -H "Content-Type: application/x-www-form-urlencoded" -o /dev/null 2>/dev/null
  set -l response (curl -sk -b /tmp/ts-cookies -X POST http://localhost/api/v1/sketches/ \
    -H "Content-Type: application/json" \
    -H "X-CSRFToken: $csrf" \
    -d "{\"name\": \"$name\", \"description\": \"$desc\"}" 2>/dev/null)
  set -l sketch_id (echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('objects',[[]])[0].get('id',''))" 2>/dev/null)
  if test -n "$sketch_id"
    printf "Sketch '%s' created (id: %s)\n" "$name" "$sketch_id"
    printf "View at: https://localhost/sketch/%s/\n" "$sketch_id"
  else
    printf "Failed to create sketch. Is Timesketch running?\n"
    return 1
  end
end

function timesketch-import
  if test (count $argv) -eq 0; or test "$argv[1]" = "-h"
    printf "Usage: timesketch-import TIMELINEFILE\n\n"
    return 0
  end
  if not _container_running timesketch-web
    printf "Timesketch is not running. Start it with: starttimesketch\n"
    return 1
  end
  docker compose -f /opt/timesketch/docker-compose.yml exec timesketch-web tsctl list-sketches
  read -P "Enter the sketch to import the timeline to: " SKETCH
  timesketch_importer --sketch_id $SKETCH $argv[1]
end

# --- Course Materials ---

function course-update
  if not test -d /opt/courses
    printf "Course materials not installed at /opt/courses\n"
    return 1
  end
  git -C /opt/courses pull 2>/dev/null
  docker compose -f /opt/courses/compose.yml pull
  docker compose -f /opt/courses/compose.yml up -d
  printf "Course materials updated and available at http://localhost:8000\n"
end

# --- Hashsets ---

function update-hashsets
  _service_dir /opt/clamav-hashbuilder; or return 1
  printf "Restarting clamav-hashbuilder to refresh hashsets...\n"
  docker compose -f /opt/clamav-hashbuilder/compose.yml restart
  printf "Hashsets will be updated at /opt/hashsets\n"
end

# --- System Update ---

function greymhatter-update
  if not test -d /opt/greymhatter
    printf "Cloning greymhatter repository...\n"
    sudo git clone https://github.com/jknyght9/greymhatter.git /opt/greymhatter
  else
    sudo git -C /opt/greymhatter pull
  end
  printf "Running Ansible playbook...\n"
  sudo ansible-playbook -i /opt/greymhatter/ansible/inventory/local.ini /opt/greymhatter/ansible/playbook.yml --extra-vars greymhatter_repo_path=/opt/greymhatter
end

# --- Disk Management ---

function disk-expand
  if test (count $argv) -eq 0; or test "$argv[1]" = "-h"
    printf "Usage: disk-expand [status|grow]\n"
    printf "  status  Show physical disk, PV, LV, and filesystem sizes\n"
    printf "  grow    Expand root LV to fill available disk space (requires sudo)\n\n"
    return 0
  end

  # Discover the PV backing the fedora VG
  set -l pv_device (sudo pvs --noheadings -o pv_name -S vg_name=fedora 2>/dev/null | string trim)
  if test -z "$pv_device"
    printf "Error: Could not find a PV for volume group 'fedora'\n"
    return 1
  end

  # Bail if multiple PVs
  if test (count (string split \n -- $pv_device)) -gt 1
    printf "Error: Multiple PVs found in VG fedora — manual expansion required\n"
    return 1
  end

  # Parse parent disk and partition number
  if string match -q '/dev/nvme*' $pv_device
    set -l disk (string replace -r 'p[0-9]+$' '' $pv_device)
    set -l partnum (string replace -r '.*p' '' $pv_device)
  else
    set -l disk (string replace -r '[0-9]+$' '' $pv_device)
    set -l partnum (string replace -r '.*[^0-9]' '' $pv_device)
  end

  # Get sizes for comparison
  set -l disk_bytes (lsblk -bdno SIZE $disk 2>/dev/null)
  set -l part_bytes (lsblk -bdno SIZE $pv_device 2>/dev/null)
  set -l disk_size (lsblk -dno SIZE $disk 2>/dev/null | string trim)
  set -l part_size (lsblk -no SIZE $pv_device 2>/dev/null | string trim)
  set -l pv_size (sudo pvs --noheadings -o pv_size --units g -S vg_name=fedora 2>/dev/null | string trim)
  set -l pv_free (sudo pvs --noheadings -o pv_free --units g -S vg_name=fedora 2>/dev/null | string trim)
  set -l lv_size (sudo lvs --noheadings -o lv_size --units g fedora/root 2>/dev/null | string trim)
  set -l fs_info (command df -h / --output=size,used,avail,pcent | tail -1 | string trim)

  switch $argv[1]
    case status
      printf "Disk:        %s  (%s)\n" $disk $disk_size
      printf "Partition:   %s  (%s)\n" $pv_device $part_size
      printf "PV size:     %s  (free: %s)\n" $pv_size $pv_free
      printf "LV size:     %s  (/dev/fedora/root)\n" $lv_size
      printf "Filesystem:  %s\n" $fs_info
      printf "\n"
      if test "$disk_bytes" -gt "$part_bytes" 2>/dev/null
        printf "Expansion available — run 'disk-expand grow' to use unallocated space\n"
      else
        printf "Disk is fully allocated, no expansion needed\n"
      end

    case grow
      if test "$disk_bytes" -le "$part_bytes" 2>/dev/null
        printf "No unallocated space on %s — nothing to do\n" $disk
        return 0
      end

      printf "=== Before ===\n"
      printf "Disk: %s  Partition: %s  LV: %s\n\n" $disk_size $part_size $lv_size

      printf "Fixing GPT backup header...\n"
      sudo sgdisk -e $disk 2>/dev/null; or true

      printf "Growing partition %s on %s...\n" $partnum $disk
      set -l gp_out (sudo growpart $disk $partnum 2>&1)
      if test $status -ne 0
        if string match -q '*NOCHANGE*' $gp_out
          printf "Partition already fills the disk\n"
        else
          printf "Error: growpart failed: %s\n" $gp_out
          return 1
        end
      end

      printf "Resizing physical volume...\n"
      sudo pvresize $pv_device; or return 1

      printf "Extending logical volume...\n"
      sudo lvextend -l +100%FREE /dev/fedora/root 2>/dev/null; or true

      printf "Growing XFS filesystem...\n"
      sudo xfs_growfs /; or return 1

      # Show after state
      set -l new_part_size (lsblk -no SIZE $pv_device 2>/dev/null | string trim)
      set -l new_lv_size (sudo lvs --noheadings -o lv_size --units g fedora/root 2>/dev/null | string trim)
      set -l new_fs_info (df -h / --output=size,used,avail,pcent | tail -1 | string trim)

      printf "\n=== After ===\n"
      printf "Partition: %s  LV: %s\n" $new_part_size $new_lv_size
      printf "Filesystem: %s\n" $new_fs_info
      printf "\nDisk expansion complete.\n"

    case '*'
      printf "Unknown command: %s (use 'status' or 'grow')\n" $argv[1]
      return 1
  end
end

starship init fish | source

# --- Fastfetch ---
if not set -q SSH_CONNECTION
  if type -q fastfetch
    fastfetch
  end
end
