# Docker Valheim Server Images

This Docker image provides a Valheim dedicated server, supporting **both `amd64` and `arm64` (x86, arm) architectures.**

![Teriyakidactyl Delivers!™](/images/teriyakidactyl_valheim.png)

**_Teriyakidactyl Delivers!™_**

## Features

- Supports `amd64` and `arm64` architectures
- Runs under non-root user
- Automatic server updates via [steamcmd](https://developer.valvesoftware.com/wiki/SteamCMD) (on reboot)
- Cross-platform compatibility using [Box86](https://github.com/ptitSeb/box86)/[Box64](https://github.com/ptitSeb/box64) for `arm64` systems (tested on [Oracle Ampere](https://www.oracle.com/cloud/compute/arm/))
- Lightweight running only the minimal packages required for stability
- Colored :rainbow: (even in Portainer), organized logs

![Teriyakidactyl Delivers!™](/images/logs.png)

## Environment Variables

Configure your server using the following environment variables:

- `APP_FILES`: Optional directory redirect for Valheim server files (default: `/app`)
- `SERVER_PUBLIC`: Set server visibility (default: "0" for private)
- `SERVER_PASS`: Server password (default: "MySecretPassword")
- `SERVER_NAME`: Server name (default: "MyValheimServer")
- `WORLD_NAME`: World name (default: "Teriyakolypse")
- `WORLD_FILES`: Optional directory redirect for world files (default: `/world`)

## Usage

1. Pull the image:
   
```bash
docker pull ghcr.io/teriyakidactyl/docker-valheim-server:latest
```

2. Run the container:
   
```bash
UR_PATH="/root/valheim"
mkdir -p $UR_PATH/world  $UR_PATH/app

docker run -d \
-e SERVER_NAME="My Server" \
-e WORLD_NAME="Teriyakolypse" \
-e SERVER_PASS="secret" \
-v $UR_PATH/world:/world \
-v $UR_PATH/app:/app \
-p 2456-2457:2456-2457/udp \
--name Valheim-Server \
ghcr.io/teriyakidactyl/docker-valheim-server:latest

```

Replace `UR_PATH="/root/valheim"` with the path where you want to store your app/world data.

## Building the Image

To build the image yourself:

```docker build -t ghcr.io/teriyakidactyl/docker-valheim-server:latest .```

## Healthcheck

The container includes a basic healthcheck that verifies if the Valheim server process is running.

## Support

For issues, feature requests, or contributions, please use the GitHub issue tracker.

