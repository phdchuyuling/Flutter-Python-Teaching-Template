# Devcontainer Dockerfile for Flutter (web)
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# install essential packages
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    wget \
    unzip \
    xz-utils \
    zip \
    build-essential \
    libglu1-mesa \
    libgtk-3-0 \
    libxss1 \
    libasound2 \
    fonts-liberation \
    ca-certificates \
    gnupg \
    lsb-release \
    --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

# Install Chromium (used for Flutter web - tries several package names)
RUN apt-get update \
  && apt-get install -y --no-install-recommends chromium-browser || true \
  && apt-get install -y --no-install-recommends chromium || true \
  && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK into /workspace/.flutter-sdk to avoid permission issues
ARG FLUTTER_DIR=/workspace/.flutter-sdk
RUN git clone --depth 1 -b stable https://github.com/flutter/flutter.git ${FLUTTER_DIR}

ENV FLUTTER_ROOT=${FLUTTER_DIR}
ENV PATH=${FLUTTER_ROOT}/bin:${PATH}

# Basic Flutter setup
RUN flutter doctor -v || true
RUN flutter config --enable-web || true
RUN flutter precache --web || true

# Create a non-root user (optional) - use 'vscode' style
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME || true \
 && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME || true \
 && chown -R $USERNAME:$USERNAME /workspace || true

USER $USERNAME
WORKDIR /workspace

# default shell
SHELL ["/bin/bash", "-lc"]
