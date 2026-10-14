{ config, ... }:
{
  disks.virtio = {
    virtual = true;
    module = config.flake.modules.nixos.disk-virtio;
  };

  flake.modules.nixos.disk-virtio =
    { lib, ... }:
    {
      # virtio-blk disk. Use /dev/nvme0n1 instead if your VM emulates NVMe
      storage.device = lib.mkDefault "/dev/vda";
    };
}
