{ ... }:
{
  deviceTypes.turtlebot3-vm = {
    compute = "x86";
    disk = "virtio";
    robot = "turtlebot3";
    virtual = true;
  };

  devices.turtlebot3-vm = {
    deviceType = "turtlebot3-vm";
    ip = "192.168.68.150"; # Same IP as turtlebot3-dev; never deployed together
  };
}
