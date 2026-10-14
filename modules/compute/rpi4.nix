{
  config,
  inputs,
  self,
  ...
}:
let
  # Nix binary cache for `nixos-raspberrypi`
  cache = config.caches.nixos-raspberrypi;
in
{
  compute.rpi4 = {
    builder = inputs.nixos-raspberrypi.lib.nixosSystem;
    supportedDisks = [
      "usb-ssd"
      "microsd"
    ];
    requiresFacter = false;
    module = config.flake.modules.nixos.compute-rpi4;
  };

  flake.modules.nixos.compute-rpi4 =
    { ... }:
    let
      # `systemd.automount` settings used in `disko` configuration
      automount = [
        "noatime"
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=1min"
      ];
    in
    {
      imports = [
        inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.base # Base Raspberry Pi 4 configuration from `nixos-raspberrypi`
        self.modules.nixos.storage-layout # Defines storage.device and storage.bootPartitions
      ];

      # Add `nixos-raspberrypi` binary cache to NixOS
      nix.settings = {
        extra-substituters = [ cache.url ];
        extra-trusted-public-keys = [ cache.key ];
      };

      # Boot partitions, placed before the root partition defined in storage/layout.nix
      # Based on https://github.com/nvmd/nixos-raspberrypi-demo/blob/main/disko-usb-btrfs.nix
      storage.bootPartitions = {
        FIRMWARE = {
          label = "FIRMWARE";
          priority = 1;
          type = "0700"; # Microsoft basic data
          attributes = [
            0 # Required Partition
          ];
          size = "1024M";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot/firmware";
            mountOptions = automount;
          };
        };

        ESP = {
          label = "ESP";
          priority = 2;
          type = "EF00"; # EFI System Partition (ESP)
          attributes = [
            2 # Legacy BIOS Bootable, for U-Boot to find extlinux config
          ];
          size = "1024M";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = automount ++ [ "umask=0077" ];
          };
        };
      };

      boot.tmp.useTmpfs = true;
      zramSwap.enable = true;
    };
}
