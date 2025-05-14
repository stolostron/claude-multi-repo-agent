FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install Go
ARG GO_VERSION=1.24.0
RUN wget -q https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm go${GO_VERSION}.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin:/root/go/bin

# Install Node.js
ARG NODE_VERSION=22
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# Install additional tools needed for development
RUN apt-get update && apt-get install -y \
    git \
    curl \
    make \
    wget \
    jq \
    unzip \
    build-essential \
    gh \
    && rm -rf /var/lib/apt/lists/*

# Install openai/codex
RUN npm install -g @openai/codex

# Configure Codex
RUN mkdir -p /home/vscode/.codex
COPY .devcontainer/codex.config.json /home/vscode/.codex/config.json
RUN chown -R vscode:vscode /home/vscode/.codex

# Set working directory
WORKDIR /workspace