{ config, ... }:
{
  # Configuration profile specific to the dummy robot
  # https://docs.ros.org/en/jazzy/Tutorials/Demos/dummy-robot-demo.html
  ros.profiles.dummy-robot = {
    robot =
      distro-pkgs: with distro-pkgs; [
        dummy-robot-bringup
      ];
  };

  robots.dummy-robot = {
    rosProfile = "dummy-robot";
    module = config.flake.modules.nixos.robot-dummy-robot;
  };

  # No hardware integration needed beyond the ROS profile
  flake.modules.nixos.robot-dummy-robot = { };
}
