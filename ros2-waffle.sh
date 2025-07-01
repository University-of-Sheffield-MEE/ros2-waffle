#! /usr/bin/env bash

COMMANDS=' start | stop | term '
P=$0
COMMAND=$1
B="`basename ${P}`"
USAGE="$B ${COMMANDS}"

export ROS_PROJECT_PATH=${HOME}/ros2_waffle_workspace

start() {
    xhost +local:docker
    mkdir -p ${ROS_PROJECT_PATH}
    docker compose -f docker-compose.dia-laptops.yml up -d --build
}

stop() {
    docker compose -f docker-compose.dia-laptops.yml down
}

term() {
    echo "Launching the ROS2 environment, type 'exit' to leave once you're done."
    docker exec -it ros2-waffle /bin/bash
}

case $COMMAND in 
  start|stop|term)
    eval "${COMMAND}"
    ;;
  *) 
    echo -e "Invalid Input..."
    echo -e "$USAGE"
    exit 0
    ;;
esac
