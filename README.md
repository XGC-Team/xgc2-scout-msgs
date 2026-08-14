# Scout Messages

This repository packages the ROS1 `scout_msgs` message definitions used by the
AgileX Scout base driver.

The ROS package name remains `scout_msgs` for compatibility with the recovered
vehicle code and upstream Scout driver interfaces. The Debian package names are
`ros-melodic-scout-msgs` and `ros-noetic-scout-msgs`. This is the only published
Scout message product. It replaces the retired `ros-*-xgc2-agilex-scout-msgs`
fork.

## Messages

- `ScoutStatus`
- `ScoutMotorState`
- `ScoutLightCmd`
- `ScoutLightState`

## Install

```bash
sudo apt update
sudo apt install ros-melodic-scout-msgs
```

## Smoke Test

```bash
source /opt/ros/melodic/setup.bash
rospack find scout_msgs
rosmsg show scout_msgs/ScoutStatus
```
