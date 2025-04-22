#!/bin/bash

# Simple script to run Valheim container with a custom command

# Container name
CONTAINER_NAME="valheim-server"

# Image name
IMAGE_NAME="ghcr.io/teriyakidactyl/docker-valheim-server:bookworm_dev"

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Container ${CONTAINER_NAME} already exists, stopping and removing it..."
  docker stop ${CONTAINER_NAME} >/dev/null 2>&1
  docker rm ${CONTAINER_NAME} >/dev/null 2>&1
fi

# Run the container with an overridden command
echo "Starting Valheim server container with bash shell instead of default CMD..."
docker run -it \
  --name ${CONTAINER_NAME} \
  -p 2456-2457:2456-2457/udp \
  -e SERVER_NAME="TestServer" \
  -e WORLD_NAME="TestWorld" \
  -e SERVER_PASS="testpassword" \
  ${IMAGE_NAME} \
  /bin/bash

# Note: This will drop you directly into a bash shell inside the container
# From there you can manually execute scripts or troubleshoot