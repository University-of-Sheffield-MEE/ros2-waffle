ARG ROS_VERSION=jazzy
FROM tomphoward/ros2waffle:${ROS_VERSION}

ARG ROS_VERSION
ENV DEBIAN_FRONTEND=noninteractive

RUN echo "[INFO] Install WSL-specific components" && \
    apt-get update && apt-get install -o Dpkg::Options::="--force-confnew" -fuy \
    wslu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV DEFAULT_USER=student
ENV DIAMOND_DIR=/home/diamond

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

WORKDIR ${DIAMOND_DIR}

RUN git clone https://github.com/University-of-Sheffield-MEE/ros2-waffle.git

ENV WSL_HOME_DIR=/home/${DEFAULT_USER}
ENV SCRIPTS_PATH=${WSL_HOME_DIR}/.diamond
ENV SRC_PATH=${DIAMOND_DIR}/ros2-waffle/wsl/source 

WORKDIR ${WSL_HOME_DIR}
RUN echo "[INFO] Configuring User Profile" && \
    mkdir -p ${SCRIPTS_PATH} && \
    cp ${SRC_PATH}/wsl-ros-config.sh ${SCRIPTS_PATH} && \
    cp ${SRC_PATH}/bash_aliases ${SCRIPTS_PATH} && \
    bash -c 'echo -e "\nsource '${SCRIPTS_PATH}'/wsl-ros-config.sh\n"' | tee -a ${WSL_HOME_DIR}/.bashrc && \
    sudo -u ${DEFAULT_USER} -H git config --global init.defaultBranch main && \
    sudo -u ${DEFAULT_USER} -H git config --global push.default simple

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