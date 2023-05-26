FROM --platform=amd64 didstopia/base:nodejs-12-steamcmd-ubuntu-18.04

LABEL maintainer="Didstopia <support@didstopia.com>"

# Fixes apt-get warnings
ARG DEBIAN_FRONTEND=noninteractive

## FIXME: Isn't libsdl2 already included in the base image?
# Install dependencies
RUN apt-get update && \
	  apt-get install -y --no-install-recommends \
      libsdl2-2.0-0:i386 \
      jq \
      xvfb \
      winbind \
      wine-stable \
      wine32 \
      wine64 \
      winetricks \
      screen \
      net-tools \
      iproute2 && \
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
ENV PGID 1000
ENV PUID 1000

# Expose necessary ports
EXPOSE 9876/udp
EXPOSE 9877/udp
EXPOSE 9878/tcp

# Setup environment variables for configuring the server
ENV V_RISING_SERVER_PERSISTENT_DATA_PATH     "/app/vrising"
ENV V_RISING_SERVER_BRANCH                   "public"
ENV V_RISING_SERVER_START_MODE               "0"
ENV V_RISING_SERVER_UPDATE_MODE              "0"
ENV V_RISING_SERVER_DEFAULT_HOST_SETTINGS    true
ENV V_RISING_SERVER_DEFAULT_GAME_SETTINGS    true

# Setup environment variables for customizing the server
ENV V_RISING_SERVER_NAME                     "V Rising Docker Server"
ENV V_RISING_SERVER_DESCRIPTION              "V Rising server running inside a Docker container."
# ENV V_RISING_SERVER_BIND_IP                  "127.0.0.1"
# ENV V_RISING_SERVER_BIND_IP                  "0.0.0.0"
ENV V_RISING_SERVER_BIND_IP                  ""
ENV V_RISING_SERVER_BIND_IP_AUTO_DETECT      false
ENV V_RISING_SERVER_GAME_PORT                9876
ENV V_RISING_SERVER_QUERY_PORT               9877
ENV V_RISING_SERVER_RCON_PORT                9878
ENV V_RISING_SERVER_RCON_ENABLED             true
ENV V_RISING_SERVER_RCON_PASSWORD            "s3cr3t_rc0n_p455w0rd"
ENV V_RISING_SERVER_MAX_CONNECTED_USERS      40
ENV V_RISING_SERVER_MAX_CONNECTED_ADMINS     4
ENV V_RISING_SERVER_SAVE_NAME                "docker"
ENV V_RISING_SERVER_PASSWORD                 ""
# ENV V_RISING_SERVER_LIST_ON_MASTER_SERVER    true
ENV V_RISING_SERVER_LIST_ON_STEAM            true
ENV V_RISING_SERVER_LIST_ON_EPIC_EOS         false
ENV V_RISING_SERVER_AUTO_SAVE_COUNT          50
ENV V_RISING_SERVER_AUTO_SAVE_INTERVAL       600
ENV V_RISING_SERVER_GAME_SETTINGS_PRESET     ""

ENV V_RISING_SERVER_GAME_ENABLE_PVP          false
ENV V_RISING_SERVER_GAME_DISABLE_BLOOD_DRAIN false
ENV V_RISING_SERVER_GAME_DISABLE_DECAY       false

# Define directories to take ownership of
ENV CHOWN_DIRS "/steamcmd,/app,/dev/stdout,/dev/stderr"

## FIXME: Fix for V Rising
# Expose the volumes
VOLUME [ "/steamcmd/vrising", "/app/vrising" ]

# Start the server
CMD [ "bash", "/app/start.sh" ]
