#!/bin/bash

# Build and push image with Podman

set -e

IMAGE_NAME="birthday-api"
IMAGE_TAG="latest"
REGISTRY="localhost:5000"

echo "Building image with Podman..."
podman build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "Tagging image for registry..."
podman tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

echo "Pushing to registry..."
podman push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} --tls-verify=false

echo "Done! Image available at ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"