#!/bin/bash

USERNAME="$1"

echo -e "Installing Powershell"
CWD=$(pwd)
rpm --import https://packages.microsoft.com/keys/microsoft.asc
curl https://packages.microsoft.com/config/rhel/7/prod.repo | tee /etc/yum.repos.d/microsoft.repo
dnf makecache
dnf install powershell -y
cd "$CWD"
