#!/usr/bin/env bash

# Enable error handling
set -eo pipefail

# Enable debugging
# set -x

# Ensure that RCON is enabled
if [[ "$V_RISING_SERVER_RCON_ENABLED" != "true" ]]; then
  echo "RCON is disabled, exiting.."
  exit 1
fi

mcrcon \
  -H "127.0.0.1" \
  -P "${V_RISING_SERVER_RCON_PORT}" \
  -p "${V_RISING_SERVER_RCON_PASSWORD}" \
  $@
