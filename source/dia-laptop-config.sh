ROS_DISTRO=jazzy

source ${HOME}/.diamond/bash-aliases

source /opt/ros/${ROS_DISTRO}/setup.bash
if [ -f "${HOME}/ros2_ws/install/setup.bash" ]; then
    source ${HOME}/ros2_ws/install/setup.bash
fi

export RMW_IMPLEMENTATION=rmw_zenoh_cpp
export TURTLEBOT3_MODEL=waffle
export ROS_DOMAIN_ID=1

# Colcon
source /usr/share/colcon_cd/function/colcon_cd.sh
export _colcon_cd_root=${HOME}/ros2_ws
source /usr/share/colcon_cd/function/colcon_cd-argcomplete.bash
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash

colcon() {
    # A wrapper for `colcon build`
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
