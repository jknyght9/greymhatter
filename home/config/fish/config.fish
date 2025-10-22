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

# Functions
function log2timeline
  if test (count $argv) -eq 0; or test "$argv[1]" = "-h"
    printf "Usage: log2timeline TIMELINENAME.plaso IMAGEORDIRECTORYPATH ADDITIONALARGUMENTS\n\n"
    printf "Outputting to the /opt/share/plaso directory."
    return 0
  end 
  if test (pwd) = "/opt/share"
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] $argv[3..-1]
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function log2timeline-triage
  if test (count $argv) -lt 2; or test "$argv[1]" = "-h"
    printf "Usage: log2timeline-triage TIMELINENAME.plaso IMAGEORDIRECTORYPATH\n\n"
    printf "Outputting to the /opt/share/plaso directory."
    return 0
  end 
  if test (pwd) = "/opt/share"
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2]
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function log2timeline-targeted
  if test (count $argv) -lt 3; or test "$argv[1]" = "-h"
    printf "Usage: log2timeline-targeted TIMELINENAME.plaso IMAGEORDIRECTORYPATH \"PARSERS,COMMA,SEPERATED\"\n\n"
    printf "Outputting to the /opt/share/plaso directory."
    return 0
  end 
  if test (pwd) = "/opt/share"
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] --parsers=$argv[3] --partitions "all"
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function log2timeline-full
  if test (count $argv) -lt 2; or test "$argv[1]" = "-h"
    printf "Usage: log2timeline-full TIMELINENAME.plaso IMAGEORDIRECTORYPATH\n\n"
    printf "Outputting to the /opt/share/plaso directory."
    return 0
  end 
  if test (pwd) = "/opt/share"
    sudo docker exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] --partitions "all" --vss_stores "all"
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function psort
  if test (count $argv) -lt 2; or test "$argv[1]" = "-h"
    printf "Usage: psort OUTPUTFILENAME.csv TIMELINENAME.plaso\n\n"
    printf "Timelines must be in the /opt/share/plaso directory.\n"
    printf "Outputting to the /opt/share/plaso directory."
    return 0
  end 
  if test (pwd) = "/opt/share"
    sudo docker exec -i timesketch-worker psort.py -o l2tcsv -w /share/plaso/$argv[1] /share/plaso/$argv[2]
  else 
    printf "Your current directory must be '/opt/share'"
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
  if test (count $argv) -eq 0; or test "$argv[1]" = "-h"
    printf "Usage: hayabusa-metrics DIRECTORYOFEVTXFILES\n\n"
    return 0
  end
  /opt/tools/hayabusa/hayabusa computer-metrics -d $argv[1]
  /opt/tools/hayabusa/hayabusa eid-metrics -d $argv[1]
end

function hayabusa-summary
  if test (count $argv) -lt 2; or test "$argv[1]" = "-h"
    printf "Usage: hayabusa-summary DIRECTORYOFEVTXFILES OUTPUTFILENAME\n\n"
    return 0
  end
  printf "Running command: hayabusa logon-summary -d $argv[1] -o /opt/share/hayabusa/$argv[2]-logonsummary\n\n"
  /opt/tools/hayabusa/hayabusa logon-summary -d $argv[1] -o /opt/share/hayabusa/$argv[2]-logonsummary
end

function hayabusa-timeline
  if test (count $argv) -lt 2; or test "$argv[1]" = "-h"
    printf "Usage: hayabusa-timeline DIRECTORYOFEVTXFILES\n\n"
    return 0
  end
  printf "Running command: hayabusa csv-timeline -d $argv[1] --RFC-3339 -p timesketch-verbose -U -T -G /opt/maxmind-geoipupdate/geoip_data/ -o /opt/share/hayabusa/$argv[2]-hayabusa-timeline.csv\n\n"
  /opt/tools/hayabusa/hayabusa csv-timeline -d $argv[1] --RFC-3339 -p timesketch-verbose -U -T -G /opt/maxmind-geoipupdate/geoip_data/ -o /opt/share/hayabusa/$argv[2]-hayabusa-timeline.csv
end

function startspiderfoot
  set CWD $(pwd)
  cd /opt/spiderfoot
  docker compose up -d
  cd "$CWD" 
end

function stopspiderfoot
  set CWD $(pwd)
  cd /opt/spiderfoot
  docker compose down
  cd "$CWD"
end

function starttimesketch
  set CWD $(pwd)
  cd /opt/timesketch
  docker compose up -d
  cd "$CWD" 
end

function stoptimesketch
  set CWD $(pwd)
  cd /opt/timesketch
  docker compose down
  cd "$CWD"
end

function startyeti
  set CWD $(pwd)
  cd /opt/yeti-docker/prod
  docker compose up -d
  cd "$CWD" 
end

function stopyeti
  set CWD $(pwd)
  cd /opt/yeti-docker/prod
  docker compose down
  cd "$CWD"
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
