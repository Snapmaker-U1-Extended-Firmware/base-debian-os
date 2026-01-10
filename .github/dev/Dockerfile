FROM debian:trixie

RUN apt-get update -y && \
    apt-get install -y \
      debootstrap \
      qemu-user-static \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
