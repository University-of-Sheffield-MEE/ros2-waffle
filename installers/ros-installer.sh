#!/bin/bash

OS_VER=${OS_VER:="noble"}
ROS_VER=${ROS_VER:="jazzy"}
ROS_WS=${ROS_WS:="ros2_ws"}
echo -e "${YELLOW}Target OS version >>> '$OS_VER'${NC}"
echo -e "\n${YELLOW}Target ROS version >>> ROS2 '$ROS_VER'${NC}"
echo -e "\n${YELLOW}Workspace Name >>> '$ROS_WS'${NC}"

SHARE_DIR="/home/ros"

if [ ! -f $HOME/checkpoint1 ]; then
    echo -e "### CHECKPOINT 1 (Basic Setup) ###"
    
    sudo mkdir -p $SHARE_DIR/repos/
    sudo addgroup laptopgrp
    sudo adduser "$USER" laptopgrp
    sudo adduser student laptopgrp
    sudo chown -R $USER:laptopgrp $SHARE_DIR
    cd $SHARE_DIR/repos/
    git clone -b ${ROS_VER} https://github.com/tom-howard/tuos_robotics.git
    cd ~

    # set selected sudo commands to require no password input
    sudo cp $SHARE_DIR/repos/tuos_robotics/laptops/nopwds /etc/sudoers.d/
    
    touch $HOME/checkpoint1

    echo "### CHECKPOINT 1 (Basic Setup) COMPLETE ###"

elif [ ! -f $HOME/checkpoint2 ]; then
    echo -e "### CHECKPOINT 2 (Installing ROS) ###" 
    
    ## INSTALLING ROS ###
    # Add universe repo
    sudo add-apt-repository universe

    export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
    curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"
    sudo dpkg -i /tmp/ros2-apt-source.deb
        
    echo -e "\n${YELLOW}[Source .bashrc]${NC}"
    source $HOME/.bashrc

    echo -e "\n${YELLOW}[Install all the necessary ROS and TB3 packages]${NC}"
    sudo apt install -y ros-$ROS_VER-desktop \
                        ros-dev-tools \
                        ros-$ROS_VER-gazebo-* \
                        ros-$ROS_VER-cartographer \
                        ros-$ROS_VER-cartographer-ros \
                        ros-$ROS_VER-navigation2 \
                        ros-$ROS_VER-nav2-bringup \
                        ros-$ROS_VER-turtlebot3 \
                        ros-$ROS_VER-turtlebot3-msgs \
                        ros-$ROS_VER-turtlebot3-simulations \
                        ros-$ROS_VER-turtlebot3-gazebo \
                        python3-rosdep \
                        python3-colcon-common-extensions \
                        ros-$ROS_VER-rqt* \
                        ffmpeg \
                        python3-pip \
                        python3-venv \
                        python3-pandas \
                        python3-scipy \
                        python3-venv \
                        ros-$ROS_VER-rmw-cyclonedds-cpp \
                        ros-$ROS_VER-rmw-zenoh-cpp

    source /opt/ros/$ROS_VER/setup.bash

    touch $HOME/checkpoint2

    echo "### CHECKPOINT 2 (Installing ROS) COMPLETE ###"

else
    echo -e "### CHECKPOINT 3 (Setting up TUoS Scripts) ###" 
    
    echo -e "\n${YELLOW}[Setting up the environment]"
    echo "source /opt/ros/$ROS_VER/setup.bash" >> $HOME/.bashrc

    source $HOME/.bashrc

    echo -e "\n${YELLOW}[Installing TUoS Scripts]${NC}"
        
    cd $SHARE_DIR/repos
        git clone -b ${ROS_VER} https://github.com/tom-howard/tuos_ros.git

    LAPTOP_NO=$(hostname | tr -d -c 0-9)
    echo "configuring for dia-laptop$LAPTOP_NO..."
    sleep 4

    echo -e "\n${YELLOW}[Setting up /usr/local/bin/ scripts]${NC}"
    cd $SHARE_DIR/repos/tuos_robotics/laptops/
    sudo install ros_mode /usr/local/bin/
        
    cd $SHARE_DIR/repos/tuos_robotics/laptops/diamond_tools/
    sudo install diamond_tools /usr/local/bin/
        
    cd $SHARE_DIR/repos/tuos_robotics/laptops/waffle_cli/
    sudo install waffle /usr/local/bin/
    sudo cp robot_pair_check.sh /usr/local/bin/
    sudo cp robot_pairing.sh /usr/local/bin/
    sudo cp robot_sync.sh /usr/local/bin/
        
    echo -e "\n${YELLOW}[Setting device numbers]${NC}"
    cd $SHARE_DIR
    touch laptop_number waffle_number
    echo "$LAPTOP_NO" > laptop_number
    echo "$LAPTOP_NO" > waffle_number
    sudo chown $USER:laptopgrp laptop_number waffle_number

    echo -e "\n${YELLOW}Setting up user profiles${NC}"

    mkdir -p $HOME/.diamond/diamond_tools/
    echo "[$(date +'%Y%m%d_%H%M%S')] $(date +'%Y-%m') ROS 2 ${ROS_VER} ($(hostname))" > $HOME/.diamond/base_image

    cd $SHARE_DIR/repos/tuos_robotics/laptops/diamond_tools/
    cp profile_updates.sh /tmp/ 
    cd ~
    chmod +x /tmp/profile_updates.sh
    sudo chown $USER:laptopgrp /tmp/profile_updates.sh
    # run as current user:
    /tmp/profile_updates.sh
    source $HOME/.bashrc
    diamond_tools workspace

    # setting up 'student' profile
    echo -e "\n${YELLOW}[Setting up the same environment for 'student' account]${NC}"
    cp $SHARE_DIR/repos/tuos_robotics/laptops/setup_student.sh /tmp/
    chmod +x /tmp/setup_student.sh
    sudo chown $USER:laptopgrp /tmp/setup_student.sh
    sudo -i -u student "/tmp/setup_student.sh"

    rm -f $HOME/checkpoint*

    echo "### CHECKPOINT 3 (Setting up TUoS Scripts) COMPLETE ###"

fi

sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y
