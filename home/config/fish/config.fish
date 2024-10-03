# Set paths and greeting variable
set -g -x fish_greeting ''

# Add to environment
fish_add_path ~/.local/bin/
fish_add_path /opt/tools/

# Aliases
alias cat='bat --paging=never'
alias c='clear'
alias df='duf'
alias ls='exa -l --icons --group --git --group-directories-first --time-style long-iso'
alias myip='curl https://ifconfig.co'
alias myipj='curl https://ifconfig.co/json'
alias vim=nvim

# Functions

function log2timeline
  if [ (pwd) = "/opt/share" ]
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] $argv[3..-1]
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function log2timeline-triage
  if [ (pwd) = "/opt/share" ]
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] -f /usr/share/plaso/filter_windows.txt --partitions "all"
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function log2timeline-targeted
  if [ (pwd) = "/opt/share" ]
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] --parsers="winevtx,usnjrnl,prefetch,winreg,esedb/srum" --partitions "all"
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function log2timeline-full
  if [ (pwd) = "/opt/share" ]
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] --parsers="winevtx,mft,prefetch,esedb,win_gen,winreg,olecf/olecf_automatic_destinations" --partitions "all"
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function mountewf
  ewfmount $argv[1] /mnt/ewf 
  printf "Now run 'mmls /mnt/ewf/ewf1' and get the start offset of the target partition and multiply it with the # of sectors (e.g. X * 512)"
end

function mountewfpartition
  mount -t ntfs-3g -o loop,ro,show_sys_files,stream_interface=windows,offset=$argv[1] /mnt/ewf/ewf1 /mnt/windows_mount/
end

function hayabusa-metrics
  /opt/tools/hayabusa/hayabusa computer-metrics -d $argv[1]
  /opt/tools/hayabusa/hayabusa eid-metrics -d $argv[1]
end

function hayabusa-summary
  /opt/tools/hayabusa/hayabusa logon-summary -d $argv[1] -o /opt/share/hayabusa/$argv[2]-logonsummary
end

function hayabusa-timeline
  echo -e "hayabusa csv-timeline -d $argv[1] --RFC-3339 -p timesketch-verbose -U -T -G geoip/ -o /opt/share/hayabusa/$argv[2]-hayabusa-timeline.csv"
  /opt/tools/hayabusa/hayabusa csv-timeline -d $argv[1] --RFC-3339 -p timesketch-verbose -U -T -G /opt/maxmind-geoipupdate/geoip_data/ -o /opt/share/hayabusa/$argv[2]-hayabusa-timeline.csv
end

function timesketch-import
  set CWD $(pwd)
  cd /opt/timesketch
  docker compose exec timesketch-web tsctl list-sketches
  read -P "Enter the sketch to import the timeline to: " SKETCH
  timesketch_importer --sketch_id $SKETCH $argv[1]
  cd "$CWD"
end

function netioc
  whois -h whois.cymru.com " -v $argv"
end

starship init fish | source
