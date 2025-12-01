#!/bin/bash

# Build and push image with Docker to Docker Hub

set -e

IMAGE_NAME="birthday-api"
IMAGE_TAG="1.0.1"
DOCKERHUB_USER="alopezt24"
REGISTRY="docker.io"

echo "Building image with Docker..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "Tagging image for Docker Hub..."
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}

echo "Pushing to Docker Hub..."
docker push ${REGISTRY}/${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}

echo "Done! Image available at ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
echo "Docker Hub: https://hub.docker.com/repository/docker/${DOCKERHUB_USER}/${IMAGE_NAME}"