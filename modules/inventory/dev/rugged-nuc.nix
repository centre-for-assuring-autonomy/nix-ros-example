{ config, ... }:
{
  deviceTypes.rugged-nuc = {
    compute = "x86";
    disk = "nvme";
  };

  devices.rugged-nuc = {
    deviceType = "rugged-nuc";
    ip = "144.32.33.39";
    authorizedKeys = [ config.keys.xnuc ];
    facterReport = config.flake.lib.devices.reportIfPresent ./rugged-nuc-facter.json;
  };
}
