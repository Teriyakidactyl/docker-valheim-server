#!/bin/bash

# Simple script to run and attach to a Valheim server container

# Container name
CONTAINER_NAME="valheim-server"

# Image name from your GitHub repo
IMAGE_NAME="ghcr.io/teriyakidactyl/docker-valheim-server:bookworm_dev"

# Check if the container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Container ${CONTAINER_NAME} already exists, stopping and removing it..."
  docker stop ${CONTAINER_NAME} >/dev/null 2>&1
  docker rm ${CONTAINER_NAME} >/dev/null 2>&1
fi

# Run the container in detached mode
echo "Starting Valheim server container..."
docker run -d \
  --name ${CONTAINER_NAME} \
  -p 2456-2457:2456-2457/udp \
  -e SERVER_NAME="TestServer" \
  -e WORLD_NAME="TestWorld" \
  -e SERVER_PASS="testpassword" \
  ${IMAGE_NAME}

# Wait a moment for container to initialize
echo "Waiting for container to start..."
sleep 5

# Attach to the container
echo "Attaching to container. Press Ctrl+P, Ctrl+Q to detach without stopping the container."
docker attach ${CONTAINER_NAME}