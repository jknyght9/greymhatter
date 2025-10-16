# Set paths and greeting variable
set -g -x fish_greeting ''

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
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2]
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function log2timeline-targeted
  if [ (pwd) = "/opt/share" ]
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] --parsers=$argv[3] --partitions "all"
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function log2timeline-full
  if [ (pwd) = "/opt/share" ]
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] --partitions "all" --vss_stores "all"
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
