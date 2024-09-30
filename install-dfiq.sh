#!/bin/bash

CWD=$(pwd)
cd /opt
git clone https://github.com/google/dfiq.git
sed -i 's/DFIQ_ENABLED = false/DFIQ_ENABLED = true/g'
echo -e "DFIQ Installed"
