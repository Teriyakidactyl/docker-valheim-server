# Valheim Server - Based on docker-steamcmd-server
# This Dockerfile leverages the base image that provides SteamCMD, architecture detection,
# Box86/Box64 for ARM compatibility, and other common functionality.

# The BASE_TAG argument allows specifying which version of the base image to use
ARG BASE_TAG=bookworm
FROM ghcr.io/teriyakidactyl/docker-steamcmd-server:${BASE_TAG}

# Labels for metadata
LABEL org.opencontainers.image.title="Valheim Server"
LABEL org.opencontainers.image.description="Valheim dedicated server based on docker-steamcmd-server"
LABEL org.opencontainers.image.vendor="TeriyakiDactyl"
LABEL game.title="Valheim"
LABEL game.developer="Iron Gate AB"
LABEL game.publisher="Coffee Stain Publishing"

# Game-specific environment variables
ENV \
    # Game identification
    APP_NAME="valheim" \
    APP_EXE="valheim_server.x86_64" \
    STEAM_SERVER_APPID="896660" \
    STEAM_PLATFORM_TYPE="linux" \
    \
    # Server configuration - defaults that can be overridden
    SERVER_NAME="MyValheimServer" \
    SERVER_PASS="MySecretPassword" \
    SERVER_PUBLIC="0" \
    WORLD_NAME="Teriyakolypse" \
    SERVER_PORT="2456" \
    \
    # Path for allowed players list
    STEAM_ALLOW_LIST_PATH="/world/permittedlist.txt" \
    \
    # Additional environment variables needed by Valheim
    LD_LIBRARY_PATH="/app/linux64" \
    SteamAppId="892970" \
    \
    # Log filtering for Valheim-specific logs
    LOG_FILTER_SKIP="Shader,shader,Camera,camera,CamZoom,Graphic,graphic,GUI,Gui,HDR,Mesh,null,Null,NULL,Gfx,memorysetup,audioclip,music,vendor"

# Define the command line arguments for the server
ENV APP_ARGS="\
-nographics \
-batchmode \
-name \"$SERVER_NAME\" \
-port $SERVER_PORT \
-public $SERVER_PUBLIC \
-world \"$WORLD_NAME\" \
-password \"$SERVER_PASS\" \
-savedir \"$WORLD_FILES\" \
-saveinterval 1800"

# Expose Valheim ports
# 2456 - Game port
# 2457 - Query port (must be SERVER_PORT+1)
EXPOSE 2456/udp 2457/udp

# Health check
HEALTHCHECK --interval=1m --timeout=3s CMD pidof $APP_EXE || exit 1

# Use the base image's up.sh script to start the server
CMD ["up.sh"]