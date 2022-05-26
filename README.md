# V Rising Dedicated Server (in a container)

[![Docker Automated build](https://img.shields.io/docker/automated/didstopia/vrising-server.svg)](https://hub.docker.com/r/didstopia/vrising-server/)
[![Docker build status](https://img.shields.io/docker/build/didstopia/vrising-server.svg)](https://hub.docker.com/r/didstopia/vrising-server/)
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

## License

See [LICENSE](LICENSE)
