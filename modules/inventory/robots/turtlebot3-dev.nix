{ ... }:
{
  deviceTypes.turtlebot3-rpi4-ssd = {
    compute = "rpi4";
    disk = "usb-ssd";
    robot = "turtlebot3";
  };

  devices.turtlebot3-dev = {
    deviceType = "turtlebot3-rpi4-ssd";
    ip = "192.168.68.150"; # Same IP as turtlebot3-vm; never deployed together
  };
}
