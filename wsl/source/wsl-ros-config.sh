# Custom bashrc settings for wsl_ros

: "${ROS_DISTRO:=jazzy}"

source ${HOME}/.diamond/bash_aliases

source /opt/ros/${ROS_DISTRO}/setup.bash
WS_INSTALL_DIR=$HOME/ros2_ws/install/local_setup.bash
if [ -f "${WS_INSTALL_DIR}" ]; then
  source ${WS_INSTALL_DIR}
fi

export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST # check here: https://docs.ros.org/en/jazzy/Tutorials/Advanced/Improved-Dynamic-Discovery.html
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export ROS_DOMAIN_ID=1
export TURTLEBOT3_MODEL=waffle

source /usr/share/colcon_cd/function/colcon_cd.sh
export _colcon_cd_root=/opt/ros/${ROS_DISTRO}/
source /usr/share/colcon_cd/function/colcon_cd-argcomplete.bash
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash

export WSL_ROS_VER=$(cat /home/diamond/wsl_ros_ver)
# Change terminal prompt:
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@WSL-ROS2($WSL_ROS_VER)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# # GUI/graphics:
source $HOME/.diamond/xserver.sh

if [ "${XSERVER}" = true ]; then
  ## Configuring DISPLAY for X-Server GUI apps
  ipconfig.exe | grep 'IPv4' | awk {'print $NF'} > $HOME/.diamond/ipv4s && dos2unix -q $HOME/.diamond/ipv4s
  read -r line < $HOME/.diamond/ipv4s 
  export DISPLAY=$line:0.0 && rm $HOME/.diamond/ipv4s
  
  export LIBGL_ALWAYS_INDIRECT=
fi
export LIBGL_ALWAYS_SOFTWARE=true

# WSL Ops:
export WINUSER=$(wslvar USERNAME 2>/dev/null)
export WINHOMEDRIVE=$(wslvar HOMEDRIVE 2>/dev/null)
if [ "${WINHOMEDRIVE}" == "U:" ]; then
  export MANWIN=true
  sudo mkdir -p /mnt/u
  sudo mount -t drvfs U: /mnt/u 2>/dev/null
else
  export MANWIN=false
fi

# display a wsl_ros restore prompt to the user
# if this is the first launch of WSL-ROS:
if [[ ! -f ~/.diamond/no_welcome ]]; then
  wsl_ros first-launch
fi

colcon() {
    # If the first argument is "build", check the current directory
    if [[ "$1" == "build" ]]; then
        if [ "$PWD" != "$HOME/ros2_ws" ]; then
            echo "Error: 'colcon build' must be run from $HOME/ros2_ws."
            return 1
        fi
    fi

    # Execute the actual colcon command with all provided arguments
    command colcon "$@"
}
