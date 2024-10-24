#!/bin/bash

USERNAME="$1"

CWD=$(pwd)
wget -O vol2.zip https://github.com/volatilityfoundation/volatility/releases/download/2.6.1/volatility_2.6_lin64_standalone.zip
unzip vol2.zip
mv ./volatility_2.6_lin64_standalone/volatility_2.6_lin64_standalone /home/$USERNAME/.local/bin/vol2
rm -rf vol2*

if [ -f "/home/$USERNAME/.local/bin/vol2" ]; then
  echo -e "Volatility 2 was installed"
else
  echo -e "An error occured installing Volatility 2"
fi
cd "$CWD"
