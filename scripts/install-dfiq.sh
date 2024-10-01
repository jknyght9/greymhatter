#!/bin/bash

CWD=$(pwd)
cd /opt
git clone https://github.com/google/dfiq.git
echo -e "DFIQ Installed"
cd "$CWD"
