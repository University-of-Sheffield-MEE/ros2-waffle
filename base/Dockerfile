ARG ROS_VERSION=jazzy
FROM osrf/ros:${ROS_VERSION}-desktop-full

ARG ROS_VERSION
ENV DEBIAN_FRONTEND=noninteractive

ENV DEFAULT_USER=student

RUN echo "[INFO] Update Ubuntu" && \
    apt-get update && apt-get install -o Dpkg::Options::="--force-confnew" -fuy \
    nano sudo keychain rsync software-properties-common \
    mesa-utils libglu1-mesa-dev libegl1-mesa-dev libgl1-mesa-dev libgles2-mesa-dev && \
    apt-get dist-upgrade -o Dpkg::Options::="--force-confnew" -fuy && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN echo "[INFO] Set locale" && \
    apt-get update && \
    apt-get install locales && \
    locale-gen en_GB en_GB.UTF-8 && \
    update-locale LC_ALL=en_GB.UTF-8 LANG=en_GB.UTF-8

RUN echo "[INFO] Install Other Useful Packages" && \
    apt-get update && apt-get install -y \
    cmake \
    curl \
    less \
    eog \
    vim \
    tmux \
    tree \
    wget \
    ffmpeg \
    python3-pip \
    python3-venv \
    python3-scipy \
    python3-pandas \
    python3-pydantic && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN echo "[INFO] Install Additional ROS tools" &&\
    apt-get update && apt-get install -y \
    ros-dev-tools \
    python3-rosdep \
    python3-colcon-common-extensions \
    ros-${ROS_VERSION}-gazebo-* \
    ros-${ROS_VERSION}-cartographer \
    ros-${ROS_VERSION}-cartographer-ros \
    ros-${ROS_VERSION}-navigation2 \
    ros-${ROS_VERSION}-nav2-bringup \
    ros-${ROS_VERSION}-turtlebot3 \
    ros-${ROS_VERSION}-turtlebot3-msgs \
    ros-${ROS_VERSION}-turtlebot3-simulations \
    ros-${ROS_VERSION}-rmw-cyclonedds-cpp && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN echo "[INFO] Add the 'Student' User Profile" && \
    adduser --disabled-password --gecos '' ${DEFAULT_USER} && \
    usermod -aG sudo ${DEFAULT_USER} && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' | tee -a /etc/sudoers
