# V Rising Dedicated Server (in a container)

[![Build](https://github.com/Didstopia/vrising-server/actions/workflows/build.yml/badge.svg)](https://github.com/Didstopia/vrising-server/actions/workflows/build.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/didstopia/vrising-server.svg)](https://hub.docker.com/r/didstopia/vrising-server/)
[![Docker stars](https://img.shields.io/docker/stars/didstopia/vrising-server.svg)](https://hub.docker.com/r/didstopia/vrising-server)

This image will always install/update to the latest steamcmd and V Rising server, all you have to do to update your server is to redeploy the container.

Also note that the entire `/steamcmd/vrising` folder can be mounted on the host system, which would avoid having to reinstall the game when updating or recreating the container.

## Usage

**NOTE:** _See [docker-compose.yml](docker-compose.yml) (or [Dockerfile](Dockerfile)) for more information on all available options._

### Basic

Mount ```/steamcmd/vrising``` and ```/app/vrising``` somewhere on the host to keep your data safe (first path has the server files, while the second path has the config and save files)

Run the server once to generate the default configuration files, then optionally edit them under ```/app/vrising```, or alternatively use the available environment variables to configure the server (see [docker-compose.yml](docker-compose.yml) and [Dockerfile](Dockerfile)).

### Advanced

You can control the startup mode by using ```V_RISING_SERVER_START_MODE```. This determines if the server should update and then start (mode 0), only update (mode 1) or only start (mode 2)) The default value is ```"0"```.

Note that you should also enable RCON and optionally modify the ```V_RISING_SERVER_RCON_PORT``` and ```V_RISING_SERVER_RCON_PASSWORD``` environment variables accordingly, so the container can properly send the shutdown command to the server when the proper signal has been received (it uses RCON for this).

One additional feature you can enable is fully automatic updates, meaning that once a server update hits Steam, it'll restart the server and trigger the automatic update. You can enable this by setting ```V_RISING_SERVER_UPDATE_MODE``` to ```"1"```.

You can also use a different branch via environment variables. For example, to install the latest `some_branch` version, you would simply set ```V_RISING_SERVER_BRANCH``` to ```some_branch``` (this is set to ```public``` by default), however note that the game does not have any additional branches (yet).

If using Docker for Windows *and* the File System passthrough option, make sure to add the git repo drive letter as a shared drive through the Docker GUI.

### Configuration

There are two ways to configure the server, and they can be combined.

**Hand-edit the JSON (default).** With `V_RISING_SERVER_DEFAULT_HOST_SETTINGS` and `V_RISING_SERVER_DEFAULT_GAME_SETTINGS` set to `false` (the default), the container leaves `ServerHostSettings.json` and `ServerGameSettings.json` in the mounted `/app/vrising/Settings` folder alone. Edit them once and your changes survive restarts. On first run the files are created from the server defaults.

**Env vars.** Set `V_RISING_SERVER_DEFAULT_HOST_SETTINGS` / `V_RISING_SERVER_DEFAULT_GAME_SETTINGS` to `true` to regenerate the config from the `V_RISING_SERVER_*` env vars on every boot. This overwrites manual edits, so pick one approach per file.

**JSON overrides.** For any setting without a dedicated env var, pass a JSON object that gets merged into the config last (it wins over both modes above):

```yaml
V_RISING_SERVER_HOST_SETTINGS_OVERRIDES: '{"ServerFps": 45, "LanMode": false}'
V_RISING_SERVER_GAME_SETTINGS_OVERRIDES: '{"CastleDecayRateModifier": 0.5}'
```

RCON is configured from the `V_RISING_SERVER_RCON_*` vars whenever `V_RISING_SERVER_RCON_ENABLED` is `true`, regardless of the above, so graceful shutdown keeps working.

Note: if `GameSettingsPreset` is a non-empty preset name, the server loads that preset and ignores `ServerGameSettings.json`. Set it to `""` for your game settings (or game overrides) to take effect.

## Troubleshooting

### Server crashes on startup with "More than 2048 Allocators are registered"

If the log shows a wall of `More than 2048 Allocators are registered. Reduce
allocator count`, followed by `windows exception 0xc0000005` and a wine
`setup_exception stack overflow`, you are hitting Unity's hard cap of 2048
registered memory allocators on a **high-core-count host** (commonly a many-core
Xeon, e.g. on TrueNAS Scale). V Rising (a Unity DOTS/ECS game) registers
allocators per job worker thread, and Unity defaults the worker count to roughly
`logical CPUs - 1`; on a 28C/56T box that blows past the cap and the server dies.

This image caps the worker thread count by default via
`V_RISING_SERVER_JOB_WORKER_COUNT` (default `8`), applied both through Unity's
`boot.config` (`job-worker-count=`) and the `-job-worker-count` standalone-player
argument. Lower it further if you still crash, or set it to `""`/`0` to restore
Unity's auto-detection. See Unity's
[Player command line arguments](https://docs.unity3d.com/Manual/PlayerCommandLineArguments.html)
docs for details.

## License

See [LICENSE](LICENSE)
