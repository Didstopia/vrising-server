FROM --platform=amd64 didstopia/base:nodejs-22-steamcmd-ubuntu-24.04

LABEL maintainer="Didstopia <support@didstopia.com>"

# Fixes apt-get warnings
ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies. Wine is the latest WineHQ stable; V Rising's Linux
# guidance is to track latest stable (older wine fails on the .NET deps it uses).
# The i386 arch + SteamCMD's 32-bit libs are in the base; libsdl2:i386 is not.
RUN dpkg --add-architecture i386 && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      libsdl2-2.0-0:i386 \
      jq \
      xvfb \
      winbind \
      winetricks \
      screen \
      net-tools \
      iproute2 && \
    apt-get install -y --install-recommends winehq-stable && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install VC redistributables
# RUN winetricks -q vcrun2015 vcrun2017 vcrun2019

# Create the volume directories
RUN mkdir -p /steamcmd/vrising /app/vrising

# Setup scheduling support
ADD scheduler_app/ /app/scheduler_app/
WORKDIR /app/scheduler_app
RUN npm install
WORKDIR /

# Setup global rcon command
ADD rcon.sh /usr/bin/rcon
RUN chmod a+x /usr/bin/rcon && \
    mkdir -p /tmp/mcrcon && \
    cd /tmp/mcrcon && \
    wget \
      https://github.com/Tiiffi/mcrcon/releases/download/v0.7.2/mcrcon-0.7.2-linux-x86-64.tar.gz && \
    tar -xzf mcrcon-0.7.2-linux-x86-64.tar.gz && \
    cp -f mcrcon /usr/bin/mcrcon && \
    chmod a+x /usr/bin/mcrcon && \
    rm -fr /tmp/mcrcon

# Add the steamcmd installation script
ADD install.txt /app/install.txt

# Copy scripts
ADD start_vrising.sh /app/start.sh
ADD shutdown.sh /app/shutdown.sh
ADD update_check.sh /app/update_check.sh

# Fix permissions
RUN chown -R 1000:1000 \
    /steamcmd \
    /app

# Run as a non-root user by default
ENV PGID=1000
ENV PUID=1000

# Expose necessary ports
EXPOSE 9876/udp
EXPOSE 9877/udp
EXPOSE 9878/tcp

# Setup environment variables for configuring the server
ENV V_RISING_SERVER_PERSISTENT_DATA_PATH     = "/app/vrising"
ENV V_RISING_SERVER_BRANCH                   = "public"
ENV V_RISING_SERVER_START_MODE               = "0"
ENV V_RISING_SERVER_UPDATE_MODE              = "0"
# Config management. false (default): hand-edited JSON persists. true: regenerate
# config from the V_RISING_SERVER_* env vars each boot. Note the correct ENV syntax.
ENV V_RISING_SERVER_DEFAULT_HOST_SETTINGS="false"
ENV V_RISING_SERVER_DEFAULT_GAME_SETTINGS="false"
# Optional JSON merged into the config last, regardless of the flags above.
ENV V_RISING_SERVER_HOST_SETTINGS_OVERRIDES=""
ENV V_RISING_SERVER_GAME_SETTINGS_OVERRIDES=""

# Setup environment variables for customizing the server
ENV V_RISING_SERVER_NAME                     = "V Rising Docker Server"
ENV V_RISING_SERVER_DESCRIPTION              = "V Rising server running inside a Docker container."
# ENV V_RISING_SERVER_BIND_IP                 =  "127.0.0.1"
# ENV V_RISING_SERVER_BIND_IP                 =  "0.0.0.0"
ENV V_RISING_SERVER_BIND_IP                  = ""
ENV V_RISING_SERVER_BIND_IP_AUTO_DETECT      = false
ENV V_RISING_SERVER_GAME_PORT                = 9876
ENV V_RISING_SERVER_QUERY_PORT               = 9877
ENV V_RISING_SERVER_RCON_PORT                = 9878
ENV V_RISING_SERVER_RCON_ENABLED             = true
ENV V_RISING_SERVER_RCON_PASSWORD            = "s3cr3t_rc0n_p455w0rd"
ENV V_RISING_SERVER_MAX_CONNECTED_USERS      = 40
ENV V_RISING_SERVER_MAX_CONNECTED_ADMINS     = 4
ENV V_RISING_SERVER_SAVE_NAME                = "docker"
ENV V_RISING_SERVER_PASSWORD                 = ""
ENV V_RISING_SERVER_LIST_ON_STEAM            = true
ENV V_RISING_SERVER_LIST_ON_EPIC_EOS         = false
ENV V_RISING_SERVER_AUTO_SAVE_COUNT          = 50

ENV V_RISING_SERVER_AUTO_SAVE_INTERVAL       = 300
ENV V_RISING_SERVER_GAME_SETTINGS_PRESET     = "Custom"
ENV V_RISING_SERVER_CLAN_SIZE                = 4

# Cap Unity's job worker threads to avoid the ">2048 Allocators registered"
# crash on high-core-count hosts (e.g. 28C/56T Xeon, common in TrueNAS/NAS
# builds). See start_vrising.sh for the full explanation. Set to empty/0 to let
# Unity auto-detect. NOTE: written with the correct ENV syntax (no spaces around
# '=') on purpose, so the in-image default is really "8".
ENV V_RISING_SERVER_JOB_WORKER_COUNT="8"

ENV V_RISING_SERVER_GAME_ENABLE_PVP          = false
ENV V_RISING_SERVER_GAME_DISABLE_BLOOD_DRAIN = false
ENV V_RISING_SERVER_GAME_DISABLE_DECAY       = false

# Define directories to take ownership of
ENV CHOWN_DIRS="/steamcmd,/app,/dev/stdout,/dev/stderr"
#ENV CHOWN_DIRS "/steamcmd,/app,\${V_RISING_SERVER_PERSISTENT_DATA_PATH},/dev/stdout,/dev/stderr"

# Expose the volumes
VOLUME [ "/steamcmd/vrising", "/app/vrising" ]

# Start the server
CMD [ "bash", "/app/start.sh" ]
