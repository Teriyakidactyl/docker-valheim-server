# Valheim Server - Based on docker-steamcmd-server
# The shared base owns SteamCMD, architecture adaptation, process supervision,
# and lifecycle hooks. This image supplies Valheim's application contract.

ARG BASE_IMAGE=ghcr.io/teriyakidactyl/docker-steamcmd-server
ARG BASE_TAG=bookworm
FROM ${BASE_IMAGE}:${BASE_TAG}

# Pre-FROM args must be re-declared before they can be used in image metadata.
ARG BASE_IMAGE
ARG BASE_TAG

LABEL org.opencontainers.image.title="Valheim Server" \
      org.opencontainers.image.description="Valheim dedicated server based on docker-steamcmd-server" \
      org.opencontainers.image.vendor="TeriyakiDactyl" \
      org.opencontainers.image.base.name="${BASE_IMAGE}:${BASE_TAG}" \
      game.title="Valheim" \
      game.developer="Iron Gate AB" \
      game.publisher="Coffee Stain Publishing"

ENV APP_NAME="valheim" \
    APP_EXE="valheim_server.x86_64" \
    APP_ARGS_FILE="/usr/local/share/valheim/valheim.args" \
    APP_STOP_SIGNAL="INT" \
    SHUTDOWN_TIMEOUT="30" \
    STEAM_SERVER_APPID="896660" \
    STEAM_PLATFORM_TYPE="linux" \
    SERVER_NAME="MyValheimServer" \
    SERVER_PASS="MySecretPassword" \
    SERVER_PUBLIC="0" \
    WORLD_NAME="Teriyakolypse" \
    SERVER_PORT="2456" \
    LD_LIBRARY_PATH="/app/linux64" \
    SteamAppId="892970" \
    LOG_FILTER_SKIP="Shader,shader,Camera,camera,CamZoom,Graphic,graphic,GUI,Gui,HDR,Mesh,null,Null,NULL,Gfx,memorysetup,audioclip,music,vendor"

USER root

RUN mkdir -p /usr/local/share/valheim "${HOOK_DIRECTORIES}/pre-startup"

COPY scripts/container/valheim.args /usr/local/share/valheim/valheim.args
COPY scripts/container/hooks/pre-startup/30_valheim.sh ${HOOK_DIRECTORIES}/pre-startup/30_valheim.sh

RUN chown root:root \
        /usr/local/share/valheim/valheim.args \
        "${HOOK_DIRECTORIES}/pre-startup/30_valheim.sh" && \
    chmod 0644 /usr/local/share/valheim/valheim.args && \
    chmod 0755 "${HOOK_DIRECTORIES}/pre-startup/30_valheim.sh"

USER ${CONTAINER_USER}

# Valheim uses SERVER_PORT and SERVER_PORT+1. EXPOSE documents the defaults;
# operators using another SERVER_PORT must publish the corresponding pair.
EXPOSE 2456/udp 2457/udp
