#!/bin/bash

# Build and push image with Podman to Docker Hub

set -e

IMAGE_NAME="birthday-api"
IMAGE_TAG="1.0.0"
DOCKERHUB_USER="alopezt24"
REGISTRY="docker.io"

echo "Building image with Podman..."
podman build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "Tagging image for Docker Hub..."
podman tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}

echo "Login to Docker Hub (enter your credentials)..."
podman login docker.io

echo "Pushing to Docker Hub..."
podman push ${REGISTRY}/${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}

echo "Done! Image available at ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
echo "Docker Hub: https://hub.docker.com/repository/docker/${DOCKERHUB_USER}/${IMAGE_NAME}"