#!/bin/bash

set -e

echo ">> Setting timezone to UTC..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
echo "UTC" > /etc/timezone
