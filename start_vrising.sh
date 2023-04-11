#!/usr/bin/env bash

# Enable error handling
# set -e
# set -o pipefail

# Enable debugging
# set -x

# Print the user we're currently running as
echo "Running as user: $(whoami)"

child=0

exit_handler()
{
	echo "Shutdown signal received.."

	# Execute the telnet shutdown commands
	/app/shutdown.sh
	killer=$!
	wait "$killer"

	# sleep 4

	echo "Exiting.."
	exit
}

# Trap specific signals and forward to the exit handler
trap 'exit_handler' SIGINT SIGTERM

# V Rising includes a 64-bit version of steamclient.so, so we need to tell the OS where it exists
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/steamcmd/vrising/VRisingServer_Data/Plugins/x86_64

# Create the necessary folder structure
if [ ! -d "/steamcmd/vrising" ]; then
	echo "Missing /steamcmd/vrising, creating.."
	mkdir -p /steamcmd/vrising
fi
if [ ! -d "${V_RISING_SERVER_PERSISTENT_DATA_PATH}" ]; then
	echo "Missing ${V_RISING_SERVER_PERSISTENT_DATA_PATH}, creating.."
	mkdir -p ${V_RISING_SERVER_PERSISTENT_DATA_PATH}
fi

# Define the install/update function
install_or_update()
{
	# Install V Rising from install.txt
	echo "Installing/updating V Rising.. (this might take a while, be patient)"
	/steamcmd/steamcmd.sh +runscript /app/install.txt

	# Terminate if exit code wasn't zero
	if [ $? -ne 0 ]; then
		echo "Exiting, steamcmd install or update failed!"
		exit 1
	fi
}

# Check which branch to use
if [ ! -z ${V_RISING_SERVER_BRANCH+x} ]; then
	echo "Using branch arguments: $V_RISING_SERVER_BRANCH"

	# Add "-beta" if necessary
	INSTALL_BRANCH="${V_RISING_SERVER_BRANCH}"
	if [ ! "$V_RISING_SERVER_BRANCH" == "public" ]; then
		INSTALL_BRANCH="-beta ${V_RISING_SERVER_BRANCH}"
	fi
	sed -i "s/app_update 1829350.*validate/app_update 1829350 $INSTALL_BRANCH validate/g" /app/install.txt
else
	sed -i "s/app_update 1829350.*validate/app_update 1829350 validate/g" /app/install.txt
fi

# Install/update steamcmd
echo "Installing/updating steamcmd.."
curl -s http://media.steampowered.com/installer/steamcmd_linux.tar.gz | bsdtar -xvf- -C /steamcmd

# Disable auto-update if start mode is 2
if [ "$V_RISING_SERVER_START_MODE" = "2" ]; then
	# Check that V Rising exists in the first place
	if [ ! -f "/steamcmd/vrising/VRisingServer.exe" ]; then
		install_or_update
	else
		echo "V Rising seems to be installed, skipping automatic update.."
	fi
else
	install_or_update

	# Run the update check if it's not been run before
	if [ ! -f "/steamcmd/vrising/build.id" ]; then
		/app/update_check.sh
	else
		OLD_BUILDID="$(cat /steamcmd/vrising/build.id)"
		STRING_SIZE=${#OLD_BUILDID}
		if [ "$STRING_SIZE" -lt "6" ]; then
			/app/update_check.sh
		fi
	fi
fi



# Validate that the default server configuration file exists
V_RISING_SERVER_CONFIG_FILE_DEFAULT="/steamcmd/vrising/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json"
if [ ! -f "${V_RISING_SERVER_CONFIG_FILE_DEFAULT}" ]; then
	echo "ERROR: Default server configuration file not found, are you sure the server is up to date?"
	exit 1
fi

# Validate that the default game configuration file exists
V_RISING_SERVER_GAME_CONFIG_FILE_DEFAULT="/steamcmd/vrising/VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json"
if [ ! -f "${V_RISING_SERVER_GAME_CONFIG_FILE_DEFAULT}" ]; then
	echo "ERROR: Default game configuration file not found, are you sure the server is up to date?"
	exit 1
fi



## TODO: Just loop through /Settings/* and compare all the files,
##       see if they exist or not, copy defaults or apply custom ones,
##       instead of processing them manually like this!

# Copy the default server configuration file if one doesn't yet exist
V_RISING_SERVER_CONFIG_FILE="${V_RISING_SERVER_PERSISTENT_DATA_PATH}/ServerHostSettings.json"
if [ ! -f "${V_RISING_SERVER_CONFIG_FILE}" ]; then
	echo "Server configuration file not found, creating a new one.."
	cp ${V_RISING_SERVER_CONFIG_FILE_DEFAULT} ${V_RISING_SERVER_CONFIG_FILE}
# else
#   echo "Applying custom server configuration file.."
#   cp -f ${V_RISING_SERVER_CONFIG_FILE} ${V_RISING_SERVER_CONFIG_FILE_DEFAULT}
fi

# Copy the default game configuration file if one doesn't yet exist
V_RISING_SERVER_GAME_CONFIG_FILE="${V_RISING_SERVER_PERSISTENT_DATA_PATH}/ServerGameSettings.json"
if [ ! -f "${V_RISING_SERVER_GAME_CONFIG_FILE}" ]; then
	echo "Game configuration file not found, creating a new one.."
	cp ${V_RISING_SERVER_GAME_CONFIG_FILE_DEFAULT} ${V_RISING_SERVER_GAME_CONFIG_FILE}
# else
#   echo "Applying custom game configuration file.."
#   cp -f ${V_RISING_SERVER_GAME_CONFIG_FILE} ${V_RISING_SERVER_GAME_CONFIG_FILE_DEFAULT}
fi

# Copy admin list file if one doesn't yet exist
V_RISING_SERVER_ADMIN_LIST_FILE_DEFAULT="/steamcmd/vrising/VRisingServer_Data/StreamingAssets/Settings/adminlist.txt"
V_RISING_SERVER_ADMIN_LIST_FILE="${V_RISING_SERVER_PERSISTENT_DATA_PATH}/adminlist.txt"
if [ ! -f "${V_RISING_SERVER_ADMIN_LIST_FILE}" ]; then
	echo "Admin list file not found, creating a new one.."
	cp ${V_RISING_SERVER_ADMIN_LIST_FILE_DEFAULT} ${V_RISING_SERVER_ADMIN_LIST_FILE}
else
  echo "Applying custom admin list file.."
  cp -f ${V_RISING_SERVER_ADMIN_LIST_FILE} ${V_RISING_SERVER_ADMIN_LIST_FILE_DEFAULT}
fi

# Copy ban list file if one doesn't yet exist
V_RISING_SERVER_BAN_LIST_FILE_DEFAULT="/steamcmd/vrising/VRisingServer_Data/StreamingAssets/Settings/banlist.txt"
V_RISING_SERVER_BAN_LIST_FILE="${V_RISING_SERVER_PERSISTENT_DATA_PATH}/banlist.txt"
if [ ! -f "${V_RISING_SERVER_BAN_LIST_FILE}" ]; then
	echo "Ban list file not found, creating a new one.."
	cp ${V_RISING_SERVER_BAN_LIST_FILE_DEFAULT} ${V_RISING_SERVER_BAN_LIST_FILE}
else
  echo "Applying custom ban list file.."
  cp -f ${V_RISING_SERVER_BAN_LIST_FILE} ${V_RISING_SERVER_BAN_LIST_FILE_DEFAULT}
fi

## TODO: This is a bit dumb at the moment, as it's always replacing the file,
##       even though it doesn't strictly need to, but same goes for the files above..
# Setup and/or configure RCON
cat "${V_RISING_SERVER_CONFIG_FILE}" | jq '.Rcon = { "Enabled": env.V_RISING_SERVER_RCON_ENABLED|test("true"), "Password": env.V_RISING_SERVER_RCON_PASSWORD, "Port": env.V_RISING_SERVER_RCON_PORT|tonumber }' > "/tmp/ServerHostSettings.json.tmp"
cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"

## FIXME: We should likely ONLY apply these when we first copy the the defaults,
##        so that users are given the option of manually being able to persist edits to the files?
## TODO: This should be refactored to use functions, to cut down on boilerplate etc.
# Apply the server settings
jq '.Name |= env.V_RISING_SERVER_NAME' "${V_RISING_SERVER_CONFIG_FILE}" > "/tmp/ServerHostSettings.json.tmp" && cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"
jq '.Description |= env.V_RISING_SERVER_DESCRIPTION' "${V_RISING_SERVER_CONFIG_FILE}" > "/tmp/ServerHostSettings.json.tmp" && cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"
jq '.Port |= env.V_RISING_SERVER_GAME_PORT|tonumber' "${V_RISING_SERVER_CONFIG_FILE}" > "/tmp/ServerHostSettings.json.tmp" && cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"
jq '.QueryPort |= env.V_RISING_SERVER_QUERY_PORT|tonumber' "${V_RISING_SERVER_CONFIG_FILE}" > "/tmp/ServerHostSettings.json.tmp" && cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"
jq '.ClanSize |= env.V_RISING_SERVER_CLAN_SIZE|tonumber' "${V_RISING_SERVER_CONFIG_FILE}" > "/tmp/ServerHostSettings.json.tmp" && cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"
jq '.MaxConnectedUsers |= env.V_RISING_SERVER_MAX_CONNECTED_USERS|tonumber' "${V_RISING_SERVER_CONFIG_FILE}" > "/tmp/ServerHostSettings.json.tmp" && cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"
jq '.MaxConnectedAdmins |= env.V_RISING_SERVER_MAX_CONNECTED_ADMINS|tonumber' "${V_RISING_SERVER_CONFIG_FILE}" > "/tmp/ServerHostSettings.json.tmp" && cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"
jq '.SaveName |= env.V_RISING_SERVER_SAVE_NAME' "${V_RISING_SERVER_CONFIG_FILE}" > "/tmp/ServerHostSettings.json.tmp" && cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"
jq '.Password |= env.V_RISING_SERVER_PASSWORD' "${V_RISING_SERVER_CONFIG_FILE}" > "/tmp/ServerHostSettings.json.tmp" && cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"
jq '.ListOnMasterServer |= env.V_RISING_SERVER_LIST_ON_MNASTER_SERVER|test("true")' "${V_RISING_SERVER_CONFIG_FILE}" > "/tmp/ServerHostSettings.json.tmp" && cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"
jq '.AutoSaveCount |= env.V_RISING_SERVER_AUTO_SAVE_COUNT|tonumber' "${V_RISING_SERVER_CONFIG_FILE}" > "/tmp/ServerHostSettings.json.tmp" && cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"
jq '.AutoSaveInterval |= env.V_RISING_SERVER_AUTO_SAVE_INTERVAL|tonumber' "${V_RISING_SERVER_CONFIG_FILE}" > "/tmp/ServerHostSettings.json.tmp" && cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"
jq '.GameSettingsPreset |= env.V_RISING_SERVER_GAME_SETTINGS_PRESET' "${V_RISING_SERVER_CONFIG_FILE}" > "/tmp/ServerHostSettings.json.tmp" && cp -f "/tmp/ServerHostSettings.json.tmp" "${V_RISING_SERVER_CONFIG_FILE}"

echo "Applying custom server configuration file.."
cp -f ${V_RISING_SERVER_CONFIG_FILE} ${V_RISING_SERVER_CONFIG_FILE_DEFAULT}

echo "Applying custom game configuration file.."
cp -f ${V_RISING_SERVER_GAME_CONFIG_FILE} ${V_RISING_SERVER_GAME_CONFIG_FILE_DEFAULT}

# Start mode 1 means we only want to update
if [ "$V_RISING_SERVER_START_MODE" = "1" ]; then
	echo "Exiting, start mode is 1.."
	exit 0
fi

# Start cron
echo "Starting scheduled task manager.."
node /app/scheduler_app/app.js &

# Construct a Windows/Wine path for the persistent data
V_RISING_SERVER_PERSISTENT_DATA_PATH_WINE="Z:$(printf "%s" "$V_RISING_SERVER_PERSISTENT_DATA_PATH" | tr '/' '\\')"

# Construct the startup command
# V_RISING_SERVER_STARTUP_COMMAND="$(cat << EOF
# -saveName "${V_RISING_SERVER_SAVE_NAME}"
# -serverName "${V_RISING_SERVER_NAME}"
# -persistentDataPath "${V_RISING_SERVER_PERSISTENT_DATA_PATH_WINE}"
# -maxConnectedUsers "${V_RISING_SERVER_MAX_CONNECTED_USERS}"
# -maxConnectedAdmins "${V_RISING_SERVER_MAX_CONNECTED_ADMINS}"
# -gamePort "${V_RISING_SERVER_GAME_PORT}"
# -queryPort "${V_RISING_SERVER_QUERY_PORT}"
# EOF
# )"
V_RISING_SERVER_STARTUP_COMMAND="$(cat << EOF
-persistentDataPath "${V_RISING_SERVER_PERSISTENT_DATA_PATH_WINE}"
EOF
)"

# Replace new lines/line breaks with whitespace
V_RISING_SERVER_STARTUP_COMMAND="${V_RISING_SERVER_STARTUP_COMMAND//$'\n'/ }"

# Set the working directory
cd /steamcmd/vrising

# Run the server
echo "Starting server with arguments: ${V_RISING_SERVER_STARTUP_COMMAND}"
xvfb-run \
  --auto-servernum \
  --server-args='-screen 0 640x480x24:32 -nolisten tcp -nolisten unix' \
  bash -c "wine /steamcmd/vrising/VRisingServer.exe ${V_RISING_SERVER_STARTUP_COMMAND}" &

child=$!
wait "$child"

echo "Exiting.."
exit
