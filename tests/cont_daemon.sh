#!/bin/bash

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

# Run the container detached
echo "Starting Valheim server container in detached mode..."
docker run -d \
  --name ${CONTAINER_NAME} \
  -p 2456-2457:2456-2457/udp \
  -e SERVER_NAME="TestServer" \
  -e WORLD_NAME="TestWorld" \
  -e SERVER_PASS="testpassword" \
  ${IMAGE_NAME}
