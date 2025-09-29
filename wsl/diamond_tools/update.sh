#!/usr/bin/env bash

SRC_DIR="/home/diamond/ros2-waffle/wsl/source"

cd ${SRC_DIR}

sudo install waffle /usr/local/bin/
sudo install wsl_ros /usr/local/bin/
sudo install diamond_tools /usr/local/bin/

SCRIPTS_PATH=${HOME}/.diamond
cd ${SCRIPTS_PATH}
rm -f bash_aliases wsl-ros-config.sh
cp ${SRC_DIR}/bash_aliases ./
cp ${SRC_DIR}/wsl-ros-config.sh ./

echo "[INFO] Update complete."
