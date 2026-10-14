{ ... }:
{
  deviceTypes.dummy-robot = {
    compute = "x86";
    disk = "virtio";
    robot = "dummy-robot";
    virtual = true;
  };

  devices.dummy-robot = {
    deviceType = "dummy-robot";
    ip = "127.0.0.1";
  };
}
