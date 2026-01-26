#!/bin/bash

set -e

# Configuration
REPO_PATH="/home/fe1tph/tom/repos/ros2-waffle/base"
DOCKER_REPO="tomphoward/ros2waffle"
ROS_VERSION="${1:-jazzy}"
IMAGE_TAG="${DOCKER_REPO}:${ROS_VERSION}"

echo "Building Docker image: ${IMAGE_TAG}"
sleep 2
cd "${REPO_PATH}"
docker build --build-arg ROS_VERSION="${ROS_VERSION}" -t "${IMAGE_TAG}" .

echo "Image built successfully: ${IMAGE_TAG}"
echo "Pushing image to Docker Hub..."
sleep 2
docker push "${IMAGE_TAG}"

echo "Successfully pushed ${IMAGE_TAG} to Docker Hub"