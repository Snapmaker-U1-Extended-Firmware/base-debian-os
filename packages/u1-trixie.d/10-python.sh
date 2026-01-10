#!/bin/bash

set -e

echo ">> Adding bookworm repository to apt sources..."
echo "deb http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list.d/bookworm.list
apt-get update

echo ">> Installing Python 3.11 and dependencies from bookworm..."
apt-get install -t bookworm -y python3 python3-venv python3-dev python3-pip
python3 --version
