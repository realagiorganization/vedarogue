FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl git make bash sudo \
       build-essential pkg-config \
       python3 python3-pip python3-venv \
       golang-go \
       rustc cargo \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for interactive work
RUN useradd -ms /bin/bash dev && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev
USER dev
WORKDIR /work

# Friendly default shell message
CMD ["bash", "-lc", "echo 'Welcome to tui-wsl (Linux container)'; echo 'Repo mounted at /work'; exec bash -i"]

