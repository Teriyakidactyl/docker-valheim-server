# Valheim Server Docker Image

This Docker image provides a customizable Valheim dedicated server, supporting both x86_64 and ARM architectures.

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
docker pull [your-docker-image-name]

2. Run the container:
docker run -d 
-p 2456-2457:2456-2457/udp 
-e SERVER_NAME="My Server" 
-e WORLD_NAME="MyWorld" 
-e SERVER_PASS="secret" 
-v /path/to/valheim/data:/world 
[your-docker-image-name]

Replace `/path/to/valheim/data` with the path where you want to store your world data.

## Building the Image

To build the image yourself:

docker build -t [your-docker-image-name] .

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

## Source

This project is open source. You can find the source code at:
[https://github.com/Mist-Hunter/valheim-docker](https://github.com/Mist-Hunter/valheim-docker)

## Support

For issues, feature requests, or contributions, please use the GitHub issue tracker.

## File Structure

```
/app/
├── bin/
│   └── myapp  (main executable)
├── config/
│   ├── config.yml
│   └── ...
├── data/
│   └── ...  (persistent data, if any)
├── logs/
│   └── ...  (if logging to files)
├── scripts/
│   ├── entrypoint.sh
│   └── ...
└── static/  (if applicable, e.g., for a web app)
```