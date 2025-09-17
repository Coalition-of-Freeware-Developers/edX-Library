# syntax=docker/dockerfile:1

# Base with GCC/Clang, CMake, Ninja, GDB, etc.
FROM mcr.microsoft.com/devcontainers/cpp:1-ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Core tooling for this repo and for running workflows locally via act
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ninja-build \
        python3 python3-pip \
        git curl ca-certificates jq \
        zip unzip xz-utils \
        pkg-config \
        docker.io \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20 for running most JavaScript-based GitHub Actions when using act
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install nektos/act for running GitHub Actions locally inside the container
RUN curl -sSL https://raw.githubusercontent.com/nektos/act/master/install.sh | bash -s -- -b /usr/local/bin

# Helpful defaults
ENV EDX_CI_MODE=ON \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

WORKDIR /workspaces/edX-Library

# Make the workspace a safe git dir (when mounted by devcontainer)
RUN git config --global --add safe.directory /workspaces/edX-Library
