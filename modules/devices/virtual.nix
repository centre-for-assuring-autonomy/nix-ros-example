{ self, lib, ... }:
let
  # Shared by both VM variants, since they don't inherit from each other
  vmNetworking = {
    virtualisation.qemu.networkingOptions = lib.mkForce [
      "-device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:57" # Incrementing QEMU's default MAC address 52:54:00:12:34:56
      "-netdev bridge,id=net0,br=br0,helper=/usr/lib/qemu/qemu-bridge-helper"
    ];

    networking.useDHCP = false;
    networking.interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.100.2";
          prefixLength = 24;
        }
      ];
      ipv4.routes = [
        {
          address = "224.0.0.0"; # ros2 multicast send/receive
          prefixLength = 4;
        }
      ];
    };
  };
in
{
  # Added to device types with `virtual = true`: runs the device as a QEMU guest
  flake.modules.nixos.virtual-qemu =
    { modulesPath, ... }:
    {
      imports = [
        self.modules.nixos.storage-layout # Defines the disko options used by vmVariantWithDisko
        (modulesPath + "/profiles/qemu-guest.nix") # Imports kernel modules needed for virtualisation
      ];

      # VMs built by `system.build.vm` will see this block, but not `vmVariantWithDisko`
      virtualisation.vmVariant = vmNetworking;

      # Only VMs built by `system.build.vmWithDisko` sees this block
      virtualisation.vmVariantWithDisko = lib.mkMerge [
        vmNetworking
        # qemu-vm.nix replaces `fileSystems` with `virtualisation.fileSystems`,
        # which disko fills in without `neededForBoot`.
        { virtualisation.fileSystems."/persist".neededForBoot = true; }
      ];
    };
}
