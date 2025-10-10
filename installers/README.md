# Basic software Install

## Requires

* Ubuntu 24.04
* Set up with an admin account only

## Downloading and Installing the "Basic" setup script

Download install script:

```bash
wget https://raw.githubusercontent.com/University-of-Sheffield-MEE/ros2-waffle/refs/heads/main/installers/dia-laptops.sh
```

Execute the install script:

```
chmod +x dia-laptops.sh && ./dia-laptops.sh
```

Then, restart the machine.

## Using the ROS Install Script

After a restart, download and install the following additional script to install ROS (again from the admin account):

```bash
wget https://raw.githubusercontent.com/University-of-Sheffield-MEE/ros2-waffle/refs/heads/main/installers/ros-installer.sh
```

```bash
chmod +x ros-installer.sh
```

Then, run the script **three times**:

```bash
./ros-installer.sh
```
