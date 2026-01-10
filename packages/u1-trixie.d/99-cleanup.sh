#!/bin/bash

set -e

echo ">> Cleaning package cache..."
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
rm -rf /var/tmp/*

echo ">> Removing build artifacts..."
find /var/log -type f -delete

echo ">> Chroot scripts execution complete"
