# Stage 1: SteamCMD Install
## Required due to (Buildx qemu) (linux/amd64) > box86 > steamcmd failing in build

FROM --platform=linux/amd64 debian:bookworm-slim AS steamcmd
ARG DEBIAN_FRONTEND=noninteractive

ENV STEAMCMD_PATH="/usr/lib/games/steam/steamcmd"

RUN apt-get update; \
    apt-get install -y curl lib32gcc-s1; \
    mkdir -p $STEAMCMD_PATH; \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C $STEAMCMD_PATH; \
    $STEAMCMD_PATH/steamcmd.sh +login anonymous +quit

# Stage 2: Final
FROM debian:bookworm-slim

# Refferences Links: 
# https://hub.docker.com/_/debian
#
# Guides
# https://pimylifeup.com/raspberry-pi-valheim-server/
# https://community.fydeos.io/t/topic/26128
#
# Arm Containers
# https://github.com/Gornius/valheim_box64
# https://github.com/Arokan13/Raspiheim
#
# x86 Container
# https://github.com/lloesche/valheim-server-docker
#
# ARM Box64 Errors
# https://github.com/ptitSeb/box64/issues/1182
#
# SteamCMD Paths schema:
# https://packages.debian.org/bookworm/i386/steamcmd/filelist

ARG DEBIAN_FRONTEND=noninteractive \
    TARGETARCH \
    PACKAGES_ARM_STEAMCMD=" \
        # required for Box86 > steamcmd, https://packages.debian.org/bookworm/libc6
        libc6:armhf" \
        \
    PACKAGES_AMD64_STEAMCMD=" \
        # required for steamcmd, https://packages.debian.org/bookworm/lib32gcc-s1-amd64-cross
        lib32gcc-s1" \
        \
    PACKAGES_VALHEIM="" \
        # Guide and error refferenced libraries. Server runs fine without:
        ## libsdl, libparty, libatomic, libsteam, libpulse
        \
    PACKAGES_ARM_BUILD=" \
        # repo keyring add, https://packages.debian.org/bookworm/gnupg
        gnupg" \
        \
    PACKAGES_BASE_BUILD=" \
        curl" \
        \
    PACKAGES_BASE=" \
        # curl, steamcmd, https://packages.debian.org/bookworm/ca-certificates
        ca-certificates \
        # timezones, https://packages.debian.org/bookworm/tzdata
        tzdata"
    
ENV \
    # Container Varaibles
    APP_NAME="valheim" \
    APP_FILES="/app" \
    APP_EXE="valheim_server.x86_64" \
    WORLD_FILES="/world" \
    STEAMCMD_PATH="/usr/lib/games/steam/steamcmd" \

    SCRIPTS="/usr/local/bin" \
    LOGS="/var/log" \
    TERM=xterm-256color \
    \
    # App Variables
    SERVER_PUBLIC="0" \
    SERVER_PASS="MySecretPassword" \
    SERVER_NAME="MyValheimServer" \
    WORLD_NAME="Teriyakolypse" \
    \
    # Log settings 
    # TODO move to file, get more comprehensive.   
    LOG_FILTER_SKIP="Shader,shader,Camera,camera,CamZoom,Graphic,graphic,GUI,Gui,HDR,Mesh,null,Null,NULL,Gfx,memorysetup,audioclip,music,vendor"     

ENV \
    # Derviative VARS
    STEAM_ALLOW_LIST_PATH="$WORLD_FILES/permittedlist.txt" 

# Set up environment, install BASE_DEPENDENCIES, and configure for different architectures
RUN set -eux; \
    \
    # Update and install common BASE_DEPENDENCIES
    apt-get update; \
    apt-get install -y --no-install-recommends \
        $PACKAGES_BASE $PACKAGES_BASE_BUILD; \
    \
    # Set local build variables
    STEAMCMD_PROFILE="/home/$APP_NAME/Steam" ;\
    STEAMCMD_LOGS="$STEAMCMD_PROFILE/logs" ;\
    APP_LOGS="$LOGS/$APP_NAME" ;\
    PUID=1000 \
    GUID=1000 \
    DIRECTORIES="$WORLD_FILES $APP_FILES $LOGS $STEAMCMD_PATH $STEAMCMD_LOGS $APP_LOGS $SCRIPTS" ;\
    \
    # Create and set up $DIRECTORIES permissions
    useradd -m -u $PUID -d /home/$APP_NAME -s /bin/bash $APP_NAME; \
    mkdir -p $DIRECTORIES; \
    ln -s /home/$APP_NAME/Steam/logs $LOGS/steamcmd; \
    chown -R $APP_NAME:$APP_NAME $DIRECTORIES; \    
    chmod 755 $DIRECTORIES; \    
    \
    # Architecture-specific setup for ARM
    if echo "$TARGETARCH" | grep -q "arm"; then \
        # Add ARM architecture and update
        dpkg --add-architecture armhf; \
        apt-get update; \
        \
        # Install ARM-specific packages
        apt-get install -y --no-install-recommends \
            $PACKAGES_ARM_STEAMCMD $PACKAGES_ARM_BUILD; \
        \
        # Add and configure Box86: https://box86.debian.ryanfortner.dev/
        curl -fsSL https://itai-nelken.github.io/weekly-box86-debs/debian/box86.list -o /etc/apt/sources.list.d/box86.list; \
        curl -fsSL https://itai-nelken.github.io/weekly-box86-debs/debian/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg; \
        \
        # Add and configure Box64: https://box64.debian.ryanfortner.dev/
        curl -fsSL https://ryanfortner.github.io/box64-debs/box64.list -o /etc/apt/sources.list.d/box64.list; \
        curl -fsSL https://ryanfortner.github.io/box64-debs/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg; \
        \
        # Update and install Box86/Box64
        apt-get update; \
        apt-get install -y --no-install-recommends \
            box64 box86; \ 
        \
        # Clean up
        apt-get autoremove --purge -y $PACKAGES_ARM_BUILD; \
    else \ 
        # AMD64 specific packages
        apt-get install -y --no-install-recommends \
            $PACKAGES_AMD64_STEAMCMD; \
    fi; \
    \
    # Final cleanup
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    apt-get autoremove --purge -y $PACKAGES_BASE_BUILD

# Change to non-root APP_NAME
USER $APP_NAME

# Copy scripts after changing to APP_NAME(user)
COPY --chown=$APP_NAME:$APP_NAME scripts $SCRIPTS
COPY \
    --from=steamcmd \
    --chown=$APP_NAME:$APP_NAME \
    # Copy user profile (8mb)
    /root/Steam $STEAMCMD_PROFILE \
    # Copy executables (300mb)
    $STEAMCMD_PATH $STEAMCMD_PATH 

# https://docs.docker.com/reference/dockerfile/#volume
VOLUME ["$APP_FILES"]
VOLUME ["$WORLD_FILES"]

EXPOSE 2456/udp 2457/udp

HEALTHCHECK --interval=1m --timeout=3s CMD pidof $APP_EXE || exit 1

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["valheim_up.sh"]