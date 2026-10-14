{ lib, ... }:
{
  deviceTypes.turtlebot3-rpi4-microsd = {
    compute = "rpi4";
    disk = "microsd";
    robot = "turtlebot3";
  };

  devices =
    lib.mapAttrs
      (_: ip: {
        deviceType = "turtlebot3-rpi4-microsd";
        inherit ip;
      })
      {
        turtlebot3-01 = "192.168.68.151";
        turtlebot3-02 = "192.168.68.152";
        turtlebot3-03 = "192.168.68.153";
      };
}
