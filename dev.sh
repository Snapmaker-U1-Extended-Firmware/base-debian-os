#!/bin/bash

set -e

IMAGE_NAME="base-debian-os-dev"
BUILD_CONTEXT=".github/dev"

if ! docker build -t "$IMAGE_NAME" "$BUILD_CONTEXT"; then
    echo "[!] Docker build failed."
    exit 1
fi

TTY_FLAG=""
[[ -t 0 ]] && TTY_FLAG="-it"

exec docker run --rm $TTY_FLAG --privileged -w "$PWD" -v "$PWD:$PWD" "$IMAGE_NAME" "$@"
