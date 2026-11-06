FROM docker.io/library/node:26-trixie-slim@sha256:c0753125a3789977aefe869cbebccf70e3cfd7ea84ca48547458f02e4f1d7146 AS node
FROM ghcr.io/astral-sh/uv:latest@sha256:b485bd65cc2cf1c9a93b3554012c9c3778cf7b1b5fd3d3096ce9e1226c97e1e6 AS uv
FROM ghcr.io/astral-sh/ruff:latest@sha256:c811563e4df1a84b563e6324f357564fcd3dd4bdeb0924409ee909147c978d91 AS ruff
FROM docker.io/rhysd/actionlint:latest@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667 AS actionlint
FROM docker.io/hadolint/hadolint:latest@sha256:32dac94127fd60b7b7e3fbfc65e1383b9b5e25c9bfd7b8536de7a539fe68a12d AS hadolint

FROM mcr.microsoft.com/devcontainers/base:trixie@sha256:71b6fe7c4e07ec747a94a72b2a17f2f8c286eaa7b1c59862888df764efb8b6c6

# Distribution packages provide native tools used by this repository.
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    bash-completion \
    build-essential \
    ca-certificates \
    curl \
    diffutils \
    file \
    findutils \
    gawk \
    git \
    jq \
    less \
    locales \
    openssh-client \
    pkg-config \
    procps \
    python3 \
    python3-pip \
    python3-venv \
    qml6-module-qtqml-workerscript \
    qml6-module-qtquick \
    qml6-module-qttest \
    qt6-declarative-dev-tools \
    ripgrep \
    ruby \
    shellcheck \
    sudo \
    tar \
    unzip \
    wget \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=node /usr/local/ /usr/local/
COPY --from=uv /uv /uvx /usr/local/bin/
COPY --from=ruff /ruff /usr/local/bin/ruff
COPY --from=actionlint /usr/local/bin/actionlint /usr/local/bin/actionlint
COPY --from=hadolint /bin/hadolint /usr/local/bin/hadolint

RUN npm install --global corepack@0.36.0 markdownlint-cli2@0.23.2 \
    && corepack enable \
    && UV_TOOL_DIR=/opt/uv-tools UV_TOOL_BIN_DIR=/usr/local/bin uv tool install zizmor==1.30.0
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 COREPACK_ENABLE_DOWNLOAD_PROMPT=0
WORKDIR /workspace
