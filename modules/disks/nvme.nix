{ config, ... }:
{
  disks.nvme = {
    virtual = false;
    module = config.flake.modules.nixos.disk-nvme;
  };

  flake.modules.nixos.disk-nvme =
    { lib, ... }:
    {
      storage.device = lib.mkDefault "/dev/nvme0n1";
    };
}
