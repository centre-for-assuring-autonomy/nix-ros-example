{ config, ... }:
{
  # Configuration profile specific to the TurtleBot3
  ros.profiles.turtlebot3 = {
    domainId = 30;

    env = {
      TURTLEBOT3_MODEL = "burger";
      LDS_MODEL = "LDS-02";
    };

    shared =
      distro-pkgs: with distro-pkgs; [
        turtlebot3-bringup
        turtlebot3-description
      ];

    robot =
      distro-pkgs: with distro-pkgs; [
        turtlebot3-node
        turtlebot3-msgs
        dynamixel-sdk
        ld08-driver
      ];

    dev =
      distro-pkgs: with distro-pkgs; [
        turtlebot3-teleop
        turtlebot3-cartographer
        turtlebot3-navigation2
      ];
  };

  robots.turtlebot3 = {
    rosProfile = "turtlebot3";
    module = config.flake.modules.nixos.robot-turtlebot3;
  };

  flake.modules.nixos.robot-turtlebot3 = {
    # USB serial access needed to communicate with OpenCR board (/dev/ttyACM0) and LiDAR (/dev/ttyUSB0)
    users.users.robot.extraGroups = [ "dialout" ];
    services.udev.extraRules = ''
      # OpenCR - verify against turtlebot3_bringup/script/99-turtlebot3-cdc.rules
      ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", ENV{ID_MM_DEVICE_IGNORE}="1", MODE:="0666"
      ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE:="0666"
    '';
  };
}
