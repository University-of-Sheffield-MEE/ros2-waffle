FROM osrf/ros:jazzy-desktop-full

ENV QT_X11_NO_MITSHM=1
ENV EDITOR=nano
ENV ROS_DISTRO=jazzy
ENV DEFAULT_USER=student
ENV HOME_DIR=/home/${DEFAULT_USER}

RUN apt-get update && apt-get install -y \
    cmake \
    curl \
    gazebo \
    libglu1-mesa-dev \
    nano \
    vim \
    python3-pip \
    python3-pydantic \
    ros-dev-tools \
    ros-${ROS_DISTRO}-cartographer \
    ros-${ROS_DISTRO}-cartographer-ros \
    ros-${ROS_DISTRO}-navigation2 \
    ros-${ROS_DISTRO}-nav2-bringup \
    ros-${ROS_DISTRO}-turtlebot3 \
    ros-${ROS_DISTRO}-turtlebot3-msgs \
    ros-${ROS_DISTRO}-turtlebot3-simulations \
    ros-${ROS_DISTRO}-turtlebot3-gazebo 
    # ros-${ROS_DISTRO}-joint-state-publisher \
    # ros-${ROS_DISTRO}-robot-localization \
    # ros-${ROS_DISTRO}-plotjuggler-ros \
    # ros-${ROS_DISTRO}-robot-state-publisher \
    # ros-${ROS_DISTRO}-ros2bag

RUN apt-get update && apt-get install -y \
    # ros-${ROS_DISTRO}-rosbag2-storage-default-plugins \
    ros-${ROS_DISTRO}-rmw-fastrtps-cpp \
    ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
    ros-${ROS_DISTRO}-rmw-zenoh-cpp \
    # ros-${ROS_DISTRO}-slam-toolbox \
    ros-${ROS_DISTRO}-rqt* \
    ros-${ROS_DISTRO}-librealsense2* \
    ros-${ROS_DISTRO}-realsense2-* \
    ros-${ROS_DISTRO}-dynamixel-sdk \
    ros-${ROS_DISTRO}-gazebo-* \
    ros-${ROS_DISTRO}-turtlesim \
    python3-rosdep \
    python3-colcon-common-extensions \
    ffmpeg \
    rviz \
    tmux \
    wget \
    xorg-dev \
    eog

RUN apt-get install -y \
    mesa-utils \
    libegl1-mesa-dev \
    libgl1-mesa-dev \
    libgles2-mesa-dev \
    python3-pandas \
    net-tools \
    iputils-ping \
    iproute2 \
    less \
    tree \
    dos2unix \
    python3-venv \
    python3-scipy

RUN useradd -ms /bin/bash ${DEFAULT_USER} \
    && echo "${DEFAULT_USER}:password" | chpasswd

RUN apt-get update && apt-get install -y sudo && \
    usermod -aG sudo ${DEFAULT_USER} && \
    echo "${DEFAULT_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Try to install starship, but don't fail if it doesn't work
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes || true

USER ${DEFAULT_USER}
WORKDIR ${HOME_DIR}

RUN touch ${HOME_DIR}/.hushlogin && \
    mkdir ${HOME_DIR}/.diamond && \
    mkdir -p ${HOME_DIR}/ros2_ws/src/ && \
    mkdir ${HOME_DIR}/.ssh

# Only add starship init if starship was successfully installed
RUN if [ -f "/usr/local/bin/starship" ]; then \
    echo 'eval "$(starship init bash)"' >> ~/.bashrc; \
    fi

COPY ./source/laptop_config.sh ${HOME_DIR}/.diamond/laptop_config.sh
COPY ./source/bash_aliases ${HOME_DIR}/.diamond/bash_aliases
RUN echo "source ~/.diamond/laptop_config.sh" >> ${HOME_DIR}/.bashrc

RUN sudo chown -R ${DEFAULT_USER}:${DEFAULT_USER} ${HOME_DIR}/.diamond

CMD ["bash", "-l"]
