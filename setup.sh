#!/bin/bash

#set -euo pipefail
export TERM=xterm

# Global variables
USERNAME='hatter'
PASSWORD='H@tt3r123!'
HOSTNAME='greymhatter'
CURRENT_DIR=$(pwd)
ARCH=$(uname -m)

# Colors for terminal outputs
C_RESET="\033[0m"
C_RED="\033[0;31m"
C_GREEN="\033[0;32m"
C_YELLOW="\033[1;33m"
C_BLUE="\033[0;34m"

# Functions for convenience
function info()         { echo -e "${C_BLUE}[+] $*${C_RESET}"; }
function doing()        { echo -e "${C_BLUE}[>] $*${C_RESET}"; }
function success()      { echo -e "${C_GREEN}[✓] $*${C_RESET}"; }
function error()        { echo -e "${C_RED}[X] $*${C_RESET}"; }
function warn()         { echo -e "${C_YELLOW}[!] $*${C_RESET}"; }
function question()     { echo -e "  ${C_YELLOW}[?] $*${C_RESET}"; }
function pressAnyKey()  { read -n 1 -s -p "$(question "Press any key to continue")"; echo; }
function checkStatus() {
  local status=$?
  local task_name="$1"

  if [[ $status -ne 0 ]]; then
    error "${task_name} failed"
    return 1
  else
    success "${task_name} completed successfully"
    return 0
  fi
  pressAnyKey
  clear
}

function header() {
  clear
  cat << "EOF"
   ___                                      _   _            
  / _ \_ __ ___ _   _ _ __ ___   /\  /\__ _| |_| |_ ___ _ __ 
 / /_\/ '__/ _ \ | | | '_ ` _ \ / /_/ / _` | __| __/ _ \ '__|
/ /_\\| | |  __/ |_| | | | | | / __  / (_| | |_| ||  __/ |   
\____/|_|  \___|\__, |_| |_| |_\/ /_/ \__,_|\__|\__\___|_|   
                |___/                                        

EOF
}

function checkRequirements() {
  if [ "$EUID" -ne 0 ]; then
    error "Must be ran as root."
    exit 1 
  fi 

  doing "Checking architecture"
  if [[ "$ARCH" == "x86_64" ]]; then
      info "\tRunning on x86_64"
  elif [[ "$ARCH" == "aarch64" ]]; then
      info "\tRunning on ARM64"
  fi
}

function updatingOS() {
  doing "Optimizing and Updating Fedora"
  echo << EOF > /etc/dnf/dnf.conf
[main]
fastestmirror=1
max_parallel_downloads=10
deltarpm=true
EOF

  systemctl stop packagekit || true
  rm -rf /var/cache/dnf /var/cache/yum
  rm -f /var/lib/rpm/__db*
  rpm --rebuilddb
  dnf clean all
  dnf makecache --refresh
  dnf upgrade --refresh -y -q
  dnf autoremove -y
  fwupdmgr get-devices
  fwupdmgr refresh --force
  fwupdmgr get-updates
  fwupdmgr update -y
}

function configuringOS() {
  doing "Setting system hostname"
  hostnamectl set-hostname "${HOSTNAME}"
  echo "${HOSTNAME}.local ${HOSTNAME}" > /etc/hosts
  echo "127.0.0.1 ${HOSTNAME}.local ${HOSTNAME}" >> /etc/hosts
  cat >> /etc/hosts <<EOF
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

  doing "Setting SELinux to permissive"
  sed -i 's/=enforcing/=permissive/g' /etc/selinux/config

  doing "Enabling SSH service"
  systemctl enable --now sshd
}

function installDocker() {
  doing "Installing Docker (signature check bypassed)"
  sudo dnf remove -y docker* containerd.io -q || true
  sudo dnf clean all
  sudo rm -rf /var/cache/dnf
  sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null << 'EOF'
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://download.docker.com/linux/fedora/$releasever/$basearch/stable
enabled=1
gpgcheck=0
EOF
  doing "Installing Docker packages with --nogpgcheck"
  sudo dnf install -y --nogpgcheck --setopt=install_weak_deps=False docker-ce docker-ce-cli containerd.io docker-buildx-plugin -q
  doing "Enabling and starting Docker"
  sudo systemctl daemon-reload
  sudo systemctl enable --now docker || true
  sudo systemctl start docker || true
  info "Docker version:"
  docker --version || error "Docker did not install correctly"

  DOCKER_COMPOSE_VERSION="2.24.0"
  doing "Installing Docker compose"
  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
  info "Docker Compose version:${NC}"
  docker compose version || error "Docker Compose did not install correctly"
}

function installGnomeRequirements() {
  doing "Installing Gnome requirements"
  dnf install gnome-shell-extension-apps-menu gnome-shell-extension-blur-my-shell \
    gnome-shell-extension-dash-to-dock gnome-shell-extension-dash-to-panel \
    gnome-shell-extension-caffeine gnome-shell-extension-user-theme gnome-terminal gnome-tweaks -y --skip-unavailable -q
}

function install3dPartySources() {
  doing "Installing CTOP"
  if [[ "$ARCH" == "aarch64" ]]; then
    wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-arm64 -O /usr/local/bin/ctop
  else
    wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
  fi
  chmod +x /usr/local/bin/ctop

  doing "Installing Starship shell"
  curl -O https://starship.rs/install.sh \
    && sh ./install.sh -f \
    && rm -f install.sh

  doing "Installing Eza (ls replacement)"
  wget -q -O - https://github.com/eza-community/eza/releases/download/v0.23.4/eza_x86_64-unknown-linux-musl.tar.gz | tar zx
  chown root:root eza
  chmod 755 eza
  mv eza /usr/local/bin
}

function installRequiredSoftware() {
  doing "Installing required software"
  dnf install afflib alacritty bat btop conky curl fish dbus-x11 duf ewftools firefox \
    git neofetch neovim ntfs-3g openssl python3 python3-pip sassc tcpdump tmux unzip \
    util-linux-user wget wireshark xorg-x11-server-utils -y --skip-unavailable --nogpgcheck -q
  installDocker
  installGnomeRequirements
  install3dPartySources
}

function createUser() {
  doing "Creating $USERNAME user"
  ENC_PASSWORD=$(openssl passwd -6 $PASSWORD)
  if id "$USERNAME" &>/dev/null; then 
    usermod -aG wheel,docker $USERNAME
    warn "$USERNAME exists"
  else 
    useradd -m -G wheel,docker $USERNAME -p "$ENC_PASSWORD" -s $(which fish)
  fi

  warn "Please login as user '$USERNAME' in another terminal or TTY to complete the user session setup."
  echo -e "1. Open new Terminal or Terminal tab"
  echo -e "2. Run 'su -l hatter'"
  echo -e "3. Run 'xdg-user-dirs-update && xdg-open .'"
  echo -e "4. Run 'exit' and close the Terminal or tab"
  warn "Once logged in, return here and press Enter to continue..."
  read -p ""

  echo -e "${GREEN}[+] Setting up user profile${NC}"
  chsh -s $(which fish) $USERNAME
  mkdir -p /home/$USERNAME/Pictures
  cp $CURRENT_DIR/media/greymhatter-background.jpg /home/$USERNAME/Pictures/background.jpg
  cp $CURRENT_DIR/media/greymhatter-logo.png /var/lib/AccountsService/icons/$USERNAME
  cp -r $CURRENT_DIR/home/conky/conkyrc /home/$USERNAME/.conkyrc
  cp -r $CURRENT_DIR/home/config/* /home/$USERNAME/.config
  cp -r $CURRENT_DIR/home/local/* /home/$USERNAME/.local 
  chmod +x /home/$USERNAME/.local/share/applications/dashboard.desktop
  git clone https://github.com/tmux-plugins/tpm /home/$USERNAME/.config/tmux/plugins/tpm
  chown -R $USERNAME:$USERNAME /home/$USERNAME
  chmod +x /home/$USERNAME/.local/share/applications/dashboard.desktop
  runuser -l $USERNAME -c 'bash -s' << 'EOF'
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
systemctl --user daemon-reload
systemctl --user enable conky.service
systemctl --user start conky.service
EOF

  doing "Setting up EWF mount points"
  mkdir -p /mnt/{ewf,windows_mount}
  chgrp -R $USERNAME /mnt/*
  chmod -R 777 /mnt/*
}

function runToolParallelInstallations() {
  # Do not put anything that requires dnf here
  doing "Installing Containers"
  sudo gnome-terminal --working-directory="$CURRENT_DIR" -- bash -c "bash ./scripts/install-containers.sh $USERNAME $PASSWORD"
  
  doing "Installing GTK Themes and Fonts"
  sudo gnome-terminal --working-directory="$CURRENT_DIR" -- bash -c "bash ./scripts/install-environment.sh $USERNAME; read -p \"Enter to continue\""

  doing "Installing Volatility2"
  sudo gnome-terminal --working-directory="$CURRENT_DIR" -- bash -c "bash ./scripts/install-volatility2.sh $USERNAME; read -p \"Enter to continue\""

  doing "Installing Volatility3"
  sudo gnome-terminal --working-directory="$CURRENT_DIR" -- bash -c "bash ./scripts/install-volatility3.sh $USERNAME; read -p \"Enter to continue\""
}

function runToolInstallation() {
  runToolParallelInstallations
  doing "Installing DFIR Tools"
  bash ./scripts/install-tools.sh $USERNAME
  checkStatus

  doing "Installing Samba"
  bash ./scripts/install-smbshare.sh "$USERNAME" "$PASSWORD"
  checkStatus

  # Do not resequence this section!
  doing "Configuring up GNOME"
  bash ./scripts/install-gnome-environment.sh "$USERNAME"
  checkStatus
}

header
checkRequirements
updatingOS
configuringOS
installRequiredSoftware
createUser
runToolInstallation
