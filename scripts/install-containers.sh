#!/bin/bash

CURRENT_DIR="$1"
USERNAME="$2"
PASSWORD="$3"

CWD=$(pwd)

# Colors for terminal outputs
C_RESET="\033[0m"
C_RED="\033[0;31m"
C_GREEN="\033[0;32m"
C_YELLOW="\033[1;33m"
C_BLUE="\033[0;34m"

# Functions for convenience
function doing()        { echo -e "${C_BLUE}[>] $*${C_RESET}"; }
function success()      { echo -e "${C_GREEN}[✓] $*${C_RESET}"; }
function error()        { echo -e "${C_RED}[X] $*${C_RESET}"; }
function pressAnyKey()  { read -n 1 -s -p "$(question "Press any key to continue")"; echo; }
function checkStatus()  {
  local status=$?
  local task_name="$1"

  if [[ $status -ne 0 ]]; then
    error "${task_name} failed"
    return 1
  else
    success "${task_name} completed successfully"
    return 0
  fi
}

doing "Installing DFIQ"
bash ./scripts/install-dfiq.sh
checkStatus "Installing DFIQ"

doing "Installing Maxmind"
bash ./scripts/install-maxmind.sh
checkStatus "Installing Maxmind"

doing "Installing Timesketch"
bash ./scripts/install-timesketch.sh "$CURRENT_DIR" "$USERNAME" "$PASSWORD"
checkStatus "Installing Timesketch"

doing "Installing Yeti"
bash ./scripts/install-yeti.sh "$USERNAME" "$PASSWORD"
checkStatus "Installing Yeti"

doing "Installing Spiderfoot"
bash ./scripts/install-spiderfoot.sh "$CURRENT_DIR"
checkStatus "Installing Spiderfoot"

doing "Installing Cyberchef"
bash ./scripts/install-cyberchef.sh "$CURRENT_DIR"
checkStatus "Installing Cyberchef"

doing "Installing Homepage - Dashboard"
bash ./scripts/install-homepage.sh "$CURRENT_DIR"
checkStatus "Installing Homepage - Dashboard"

cd "$CWD"