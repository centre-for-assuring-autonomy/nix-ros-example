{ config, ... }:
{
  disks.usb-ssd = {
    virtual = false;
    module = config.flake.modules.nixos.disk-usb-ssd;
  };

  flake.modules.nixos.disk-usb-ssd = {
    # Argon ONE M.2 case SATA SSD connected via USB
    storage.device = "/dev/disk/by-id/usb-Argon_Forty_0000000000E4-0:0";
  };
}
