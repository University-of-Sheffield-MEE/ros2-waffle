ARG ROS_VERSION=jazzy
FROM tomphoward/ros2waffle:${ROS_VERSION}

ARG ROS_VERSION
ENV DEBIAN_FRONTEND=noninteractive

ENV DEFAULT_USER=student

ENV QT_X11_NO_MITSHM=1
ENV EDITOR=nano

RUN apt-get update && apt-get install -y \
    xorg-dev \
    net-tools \
    iputils-ping \
    iproute2 \
    dos2unix && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Try to install starship, but don't fail if it doesn't work
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes || true

USER ${DEFAULT_USER}
ARG HOME_DIR=/home/${DEFAULT_USER}
WORKDIR ${HOME_DIR}

RUN touch ${HOME_DIR}/.hushlogin && \
    mkdir ${HOME_DIR}/.diamond && \
    mkdir -p ${HOME_DIR}/ros2_ws/src/ && \
    mkdir ${HOME_DIR}/.ssh

# Only add starship init if starship was successfully installed
RUN if [ -f "/usr/local/bin/starship" ]; then \
    echo 'eval "$(starship init bash)"' >> ~/.bashrc; \
    fi

COPY ./source/dia-laptop-config.sh ${HOME_DIR}/.diamond/dia-laptop-config.sh
COPY ./source/bash-aliases ${HOME_DIR}/.diamond/bash-aliases
RUN echo "source ~/.diamond/dia-laptop-config.sh" >> ${HOME_DIR}/.bashrc

RUN sudo chown -R ${DEFAULT_USER}:${DEFAULT_USER} ${HOME_DIR}/.diamond

CMD ["bash", "-l"]
