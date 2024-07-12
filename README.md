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

## Docker Image Tags

Our Docker images are tagged using a comprehensive scheme to ensure proper versioning and traceability. The tagging strategy is as follows:

1. **Branch-based tags:**
   - For the `main` branch: `ghcr.io/teriyakidactyl/docker-valheim-server:main`
   - For the `dev` branch: `ghcr.io/teriyakidactyl/docker-valheim-server:dev`
   - For other branches: `ghcr.io/teriyakidactyl/docker-valheim-server:<branch-name>`

2. **Pull Request tags:**
   - For pull requests: `ghcr.io/teriyakidactyl/docker-valheim-server:pr-<PR-number>`

3. **Semantic Version tags:**
   - When a git tag with a semantic version is pushed (e.g., v1.2.3):
     - `ghcr.io/teriyakidactyl/docker-valheim-server:1.2.3`
     - `ghcr.io/teriyakidactyl/docker-valheim-server:1.2`

4. **Commit SHA tags:**
   - Each build is also tagged with the full git commit SHA:
     `ghcr.io/teriyakidactyl/docker-valheim-server:sha-<full-commit-hash>`

This tagging scheme allows for easy identification of images built from specific branches, pull requests, versions, or commits. It supports various use cases, from development and testing to production deployments.

- Use the branch-based tags for ongoing development and staging environments.
- Use the semantic version tags for production deployments and version tracking.
- Use the commit SHA tags for precise reproduction of builds or debugging.

The latest build from the `main` branch is always available with the `latest` tag:
`ghcr.io/teriyakidactyl/docker-valheim-server:latest`

Note: The actual availability of these tags depends on the specific git operations performed (pushes, pull requests, tagging) and the successful completion of the CI/CD pipeline.

