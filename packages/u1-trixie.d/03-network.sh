#!/bin/bash

set -e

echo ">> Configuring systemd-resolved..."
systemctl enable systemd-resolved

echo ">> Enabling SSH server..."
systemctl enable ssh

echo ">> Enabling nginx..."
systemctl enable nginx

echo ">> Enabling mosquitto..."
systemctl enable mosquitto
