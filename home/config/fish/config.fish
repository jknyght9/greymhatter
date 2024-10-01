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
    sudo podman exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] $argv[3..-1]
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function log2timeline-triage
  if [ (pwd) = "/opt/share" ]
    sudo podman exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] -f /usr/share/plaso/filter_windows.txt --partitions "all"
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function log2timeline-targeted
  if [ (pwd) = "/opt/share" ]
    sudo podman exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] --parsers="winevtx,usnjrnl,prefetch,winreg,esedb/srum" --partitions "all"
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function log2timeline-full
  if [ (pwd) = "/opt/share" ]
    sudo podman exec -i timesketch-worker log2timeline.py --status-view window --storage-file /share/plaso/$argv[1] /share/$argv[2] --parsers="winevtx,mft,prefetch,esedb,win_gen,winreg,olecf/olecf_automatic_destinations" --partitions "all"
  else
    printf "Your evidence and current directory must be '/opt/share'"
  end
end

function mountewf
  ewfmount $argv[1] /mnt/ewf 
  printf "Now run 'mmls /mnt/ewf/ewf1' and get the start offset of the target partition and multiply it with the # of sectors (e.g. X * 512)"
end

function mountewfpartition
  mount -t ntfs-3g -o loop,ro,show_sys_files,stream_interface=windows,offset=argv[1] /mnt/ewf/ewf1 /mnt/windows_mount/
end

function netioc
    whois -h whois.cymru.com " -v $argv"
end

conky -q -d -a tm > /dev/null &
starship init fish | source
