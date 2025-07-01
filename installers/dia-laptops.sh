#!/bin/bash

# Basic installation script for Robotics laptops
# Assumes a fresh Ubuntu 24.04 installation

student_user="student"
echo -e "\n### Creating the '${student_user}' user account ###\n"
sudo useradd -s /bin/bash -m "$student_user"
echo -e "\n### Enter the password for the '${student_user}' user account... ###\n"
sudo passwd "${student_user}"

echo -e "\n### Installing core apps ###\n"
sudo apt update && sudo apt upgrade -y

sudo apt install -y chrony \
                    ntpdate \
                    curl \
                    ca-certificates \
                    build-essential \
                    net-tools \
                    vlc \
                    gnome-clocks \
                    software-properties-common \
                    apt-transport-https \
                    wget \
                    gpg \
                    tmux \
                    tree \
                    llvm-dev \
                    libclang-dev

echo -e "\n### Installing VS Code ###\n"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
sudo apt update
sudo apt install -y code

# install OBS Studio:
echo -e "\n### Installing OBS Studio ###\n"
sudo add-apt-repository ppa:obsproject/obs-studio
sudo apt update && sudo apt install -y obs-studio

# update git:
echo -e "\n### Updating Git ###\n"
sudo add-apt-repository ppa:git-core/ppa
sudo apt update && sudo apt install -y git

# Set locales
sudo apt update && sudo apt install -y locales
sudo locale-gen en_GB en_GB.UTF-8
sudo update-locale LC_ALL=en_GB.UTF-8 LANG=en_GB.UTF-8

# Enable multicast on loopback (via a startup service) 
sudo wget -O /etc/systemd/system/multicast-lo.service \
    https://raw.githubusercontent.com/University-of-Sheffield-MEE/ros2-waffle/refs/heads/main/installers/multicast-lo.service
sudo systemctl enable multicast-lo.service

echo -e "\n### Connecting to DIA-LAB SSID ###\n"
SSID_CURRENT=$(iwgetid -r)
sudo nmcli --ask dev wifi connect DIA-LAB
echo -e "\n### Connected to: $(iwgetid -r) ###\n"
echo -e "\n### Connecting back to '$SSID_CURRENT'... ###\n"
sudo nmcli dev wifi connect $SSID_CURRENT

echo -e "\n### Installing Docker ###\n"
# Add Docker's official GPG key:
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce \
                    docker-ce-cli \
                    containerd.io \
                    docker-buildx-plugin \
                    docker-compose-plugin
sudo groupadd docker
sudo usermod -aG docker ${USER}
sudo usermod -aG docker ${student_user}

echo -e "\n### Installing NVIDIA Drivers and Container Toolkit ###\n"
sudo apt install -y nvidia-driver-570
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update
export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.17.8-1
sudo apt install -y nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
                    nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
                    libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
                    libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y
