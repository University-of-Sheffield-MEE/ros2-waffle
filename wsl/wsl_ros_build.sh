#! /usr/bin/env bash

CONTAINER_NAME=wsl-ros2
VERSION=2526.01
XSERVER=true

error () {
  echo
  echo "[build_wsl_img.sh] An error occurred at line ${2}"
  exit ${1}
}
trap 'error $? $LINENO' ERR

clear_container () {
  set +e
  [ "$(docker container inspect -f '{{.State.Running}}' ${CONTAINER_NAME} 2> /dev/null)" == "true" ] && docker stop ${CONTAINER_NAME} > /dev/null
  docker container rm ${CONTAINER_NAME} > /dev/null 2>&1
  set -e
}

# Stop and remove the container
clear_container

export VERSION_STRING="v${VERSION}-$(date +'%Y%m%d')"
export OUTPUT_NAME=$(echo ${CONTAINER_NAME} | tr _ -)

echo "# Building image v${VERSION}..."
echo
docker build --rm --no-cache --build-arg VERSION=${VERSION} --build-arg XSERVER=${XSERVER} . -t ${CONTAINER_NAME}:latest

mkdir -p builds
mkdir -p diamond_tools/update_triggers

OUTPUT_FILE=builds/${OUTPUT_NAME}-${VERSION_STRING}.tar
RELEASE_FILE_NAME=${OUTPUT_NAME}-v${VERSION}.tar
RELEASE_FILE=builds/${RELEASE_FILE_NAME}

echo
echo "# Exporting image v${VERSION}..."
echo
docker run -d --name ${CONTAINER_NAME} ${CONTAINER_NAME}:latest > /dev/null
docker export ${CONTAINER_NAME} -o ${OUTPUT_FILE}

echo "0" > diamond_tools/update_triggers/remote_ver_${VERSION}

sed -i '2s/.*/[string]$TarBallName = \"'${RELEASE_FILE_NAME}'\"/' man_win/WSL-ROS2-Start.ps1

echo "Creating a release version (${RELEASE_FILE_NAME})..."
cp ${OUTPUT_FILE} ${RELEASE_FILE}

# Stop and remove the container
clear_container

echo
echo "# Image exported to ${OUTPUT_FILE}"