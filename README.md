# Valheim Server Docker Image

This Docker image provides a customizable Valheim dedicated server, supporting **both x86_64 and ARM architectures.**

![Teriyakidactyl Delivers!™](/images/teriyakidactyl_valheim.png)

## Features

- Supports x86_64 and ARM architectures
- Automatic server updates
- Customizable server settings
- Cross-platform compatibility using Box86/Box64 for ARM systems

## Environment Variables

Configure your server using the following environment variables:

- `APP_FILES`: Directory for Valheim server files (default: "/app")
- `WORLD_FILES`: Directory for world files (default: "/world")
- `SERVER_PUBLIC`: Set server visibility (default: "0" for private)
- `SERVER_PASS`: Server password (min. 5 characters, default: "MySecretPassword")
- `SERVER_NAME`: Server name (default: "MyValheimServer")
- `WORLD_NAME`: World name (default: "DedicatedWorld")
- `APP_NAME`: APP_NAME running the server (default: "valheim")
- `STEAM_APPID`: Steam App ID for Valheim (default: "896660")
- `SERVER_ARGS`: Enable/disable crossplay (set in your docker-compose or run command)

## Usage

1. Pull the image:
docker pull [ghcr.io/teriyakidactyl/docker-valheim-server:lateste]

2. Run the container:
docker run -d 
-p 2456-2457:2456-2457/udp 
-e SERVER_NAME="My Server" 
-e WORLD_NAME="MyWorld" 
-e SERVER_PASS="secret" 
-v /path/to/valheim/data:/world 
[ghcr.io/teriyakidactyl/docker-valheim-server:latest]

Replace `/path/to/valheim/data` with the path where you want to store your world data.

## Building the Image

To build the image yourself:

docker build -t [ghcr.io/teriyakidactyl/docker-valheim-server:latest] .

The Dockerfile includes a conditional build stage for ARM architectures, which compiles Box86 and Box64 for compatibility.

## Scripts

The image includes several scripts to manage the server:

- `entrypoint.sh`: The main entry point, sets up the environment and starts the server.
- `server_update.sh`: Checks for and applies server updates.
- `server_process.sh`: Configures and runs the Valheim server process.

## Notes

- The server password must be at least 5 characters long and cannot be part of the server name.
- For ARM systems, the server uses Box64 to run the x86_64 Valheim server binary.
- The server runs on ports 2456-2457 UDP.

## Healthcheck

The container includes a basic healthcheck that verifies if the Valheim server process is running.

## Support

For issues, feature requests, or contributions, please use the GitHub issue tracker.

