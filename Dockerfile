# Stage 1: SteamCMD Install
FROM --platform=linux/amd64 debian:bookworm-slim AS steamcmd

# Needs to be in it's own stage, as box86 won't run in qemu during arm phase. Just copy
ENV STEAMCMD_PATH="/steamcmd"

RUN apt-get update; \
    apt-get install -y curl lib32gcc-s1; \
    mkdir -p $STEAMCMD_PATH; \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C $STEAMCMD_PATH; \
    $STEAMCMD_PATH/steamcmd.sh +login anonymous +quit

FROM debian:bookworm-slim
# https://hub.docker.com/_/debian

# Guides
# https://pimylifeup.com/raspberry-pi-valheim-server/
# https://community.fydeos.io/t/topic/26128

# Arm Containers
# https://github.com/Gornius/valheim_box64
# https://github.com/Arokan13/Raspiheim

# x86 Container
# https://github.com/lloesche/valheim-server-docker

# ARM Box64 Errors
# https://github.com/ptitSeb/box64/issues/1182

ARG DEBIAN_FRONTEND=noninteractive \
    TARGETARCH \
    SOURCE_COMMIT \
    PACKAGES_ARM_STEAMCMD=" \
        # https://packages.debian.org/bookworm/libc6 
        # required for Box86 > steamcmd
        libc6:armhf" \
        \
    PACKAGES_AMD64_STEAMCMD=" \
        # https://packages.debian.org/bookworm/lib32gcc-s1 
        # steamcmd won't run without
        lib32gcc-s1" \
        \
    PACKAGES_VALHEIM="" \
        # https://packages.debian.org/bookworm/libatomic1 runs fine without.
        # libatomic1 \
        # https://packages.debian.org/bookworm/libpulse-dev ,runs fine without.
        # libpulse-dev \
        \
        # NOTE the following packages are refferenced in errors on arm64 but seem to run fine without.
        ## libsdl https://packages.debian.org/search?keywords=libsdl
        ## libparty
        ## libatomic https://packages.debian.org/bookworm/libatomic1
        ## libsteam
        ## libpulse https://packages.debian.org/bookworm/libpulse0
        \
    PACKAGES_ARM_BUILD=" \
        # repo keyring add
        gnupg" \
        \
    PACKAGES_BASE_BUILD=" \
        curl" \
        \
    PACKAGES_BASE=" \
        # curl, steamcmd, https://packages.debian.org/bookworm/ca-certificates
        ca-certificates \
        # https://packages.debian.org/bookworm/python3-minimal
        # python3-minimal \
        # timezones
        tzdata"
    
ENV \
    # Container Varaibles
    APP_NAME="valheim" \
    APP_FILES="/app" \
    APP_EXE="valheim_server.x86_64" \
    WORLD_FILES="/world" \
    STEAMCMD_PATH="/steamcmd" \
    SCRIPTS="/scripts" \
    LOGS="/logs" \
    PUID=1000 \
    GUID=1000 \
    TERM=xterm-256color \
    # steamcmd tries en_US.UTF-8
    LANG=C.UTF-8 \
    \
    # App Variables
    SERVER_PUBLIC="0" \
    SERVER_PASS="MySecretPassword" \
    SERVER_NAME="MyValheimServer" \
    WORLD_NAME="Teriyakolypse" \
    \
    # Log settings   
    LOG_FILTER_SKIP="Shader,shader,Camera,camera,CamZoom,Graphic,graphic,GUI,Gui,HDR,Mesh,null,Null,NULL,Gfx,memorysetup,audioclip,music,vendor"     

# Set up environment, install BASE_DEPENDENCIES, and configure for different architectures
COPY \
    --from=steamcmd \
    --chown=$APP_NAME:$APP_NAME  \
    # Copy user profile
    /root/Steam /home/$APP_NAME/Steam \
    # Copy executables
    /steamcmd $STEAMCMD_PATH; 

RUN set -eux; \
    \
    # Update and install common BASE_DEPENDENCIES
    apt-get update; \
    apt-get install -y --no-install-recommends \
        $PACKAGES_BASE $PACKAGES_BASE_BUILD; \
    \
    # Set variables
    STEAMCMD_LOGS="/home/$APP_NAME/Steam/logs";\
    APP_LOGS="$LOGS/$APP_NAME" ;\
    # TODO move $APP_FILES and $WORLD_FILES creation to function, pull from docker.
    DIRECTORIES="$WORLD_FILES $APP_FILES $LOGS $STEAMCMD_PATH $APP_LOGS $STEAMCMD_LOGS" ;\
    \
    # Create APP_NAME and set up directories and copy steamcmd
    useradd -m -u $PUID -d /home/$APP_NAME -s /bin/bash $APP_NAME; \
    mkdir -p $DIRECTORIES; \
    ln -s /home/$APP_NAME/Steam/logs /logs/steamcmd; \
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
        # Add and configure Box86: https://box64.debian.ryanfortner.dev/
        curl -fsSL https://itai-nelken.github.io/weekly-box86-debs/debian/box86.list -o /etc/apt/sources.list.d/box86.list; \
        curl -fsSL https://itai-nelken.github.io/weekly-box86-debs/debian/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg; \
        \
        # Add and configure Box64: https://box86.debian.ryanfortner.dev/
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
    # NOTE it would be great to do a first run of steamcmd here, but it fails on arm64 buildx.
    \
    # Final cleanup
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    apt-get autoremove --purge -y $PACKAGES_BASE_BUILD

# Change to non-root APP_NAME
USER $APP_NAME

# Copy scripts after changing APP_NAME
COPY scripts $SCRIPTS

# https://docs.docker.com/reference/dockerfile/#volume
VOLUME ["$APP_FILES"]
VOLUME ["$WORLD_FILES"]

LABEL org.opencontainers.image.source="https://github.com/Teriyakidactyl/docker-valheim-server"

EXPOSE 2456/udp 2457/udp

HEALTHCHECK --interval=1m --timeout=3s CMD pidof $APP_EXE || exit 1

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["$SCRIPTS/up.sh"]