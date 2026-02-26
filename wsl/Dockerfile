ARG ROS_VERSION=jazzy
FROM tomphoward/ros2waffle:${ROS_VERSION}

ARG ROS_VERSION
ENV DEBIAN_FRONTEND=noninteractive

ENV DEFAULT_USER=student

RUN echo "[INFO] Install WSL-specific components" && \
    apt-get update && apt-get install -o Dpkg::Options::="--force-confnew" -fuy \
    wslu dos2unix && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG DIAMOND_DIR=/home/diamond

RUN mkdir -p ${DIAMOND_DIR}

RUN echo "[INFO] Configure Student Profile" && \
    chown -R ${DEFAULT_USER}:${DEFAULT_USER} ${DIAMOND_DIR} && \ 
    bash -c 'echo -e "[user]\ndefault=${DEFAULT_USER}"' | tee /etc/wsl.conf

COPY source/waffle /tmp
COPY source/wsl_ros /tmp
COPY source/diamond_tools /tmp
RUN install /tmp/waffle /usr/local/bin/ && \
    install /tmp/wsl_ros /usr/local/bin/ && \
    install /tmp/diamond_tools /usr/local/bin/

USER ${DEFAULT_USER}

ARG WSL_HOME_DIR=/home/${DEFAULT_USER}
ARG SCRIPTS_PATH=${WSL_HOME_DIR}/.diamond

RUN mkdir -p ${DIAMOND_DIR}/tb3_ws/src/ && \
    git clone https://github.com/tom-howard/turtlebot3_minimal_sims.git ${DIAMOND_DIR}/tb3_ws/src/turtlebot3_minimal_sims

WORKDIR ${DIAMOND_DIR}/tb3_ws/
RUN /bin/bash -c "source /opt/ros/${ROS_VERSION}/setup.bash; colcon build" && \
    chown -R ${DEFAULT_USER}:${DEFAULT_USER} ${DIAMOND_DIR}/tb3_ws

WORKDIR ${WSL_HOME_DIR}

RUN echo "[INFO] Configuring User Profile" && \
    mkdir -p ${SCRIPTS_PATH} && \
    bash -c 'echo -e "\nsource '${SCRIPTS_PATH}'/wsl-ros-config.sh\n"' | tee -a ${WSL_HOME_DIR}/.bashrc && \
    sudo -u ${DEFAULT_USER} -H git config --global init.defaultBranch main && \
    sudo -u ${DEFAULT_USER} -H git config --global push.default simple

COPY --chown=${DEFAULT_USER}:${DEFAULT_USER} source/bash_aliases ${SCRIPTS_PATH}/bash_aliases
COPY --chown=${DEFAULT_USER}:${DEFAULT_USER} source/wsl-ros-config.sh ${SCRIPTS_PATH}/wsl-ros-config.sh

RUN echo "[INFO] Creating a ROS2 Workspace" && \
    mkdir -p ${WSL_HOME_DIR}/ros2_ws/src/

WORKDIR ${WSL_HOME_DIR}/ros2_ws/

RUN echo "[INFO] Creating a Path for a U drive (if available)" && \
    sudo mkdir -p /mnt/u

ENV COLCON_PREFIX_PATH=/home/${DEFAULT_USER}/ros2_ws/src

ARG VERSION
ARG XSERVER

RUN echo "[INFO] Store ARGs to file" && \
    echo "0" > ${DIAMOND_DIR}/local_ver && \
    echo "${VERSION}" > ${DIAMOND_DIR}/wsl_ros_ver && \
    echo "export XSERVER=${XSERVER}" > ${SCRIPTS_PATH}/xserver.sh

CMD ["bash", "-l"]
