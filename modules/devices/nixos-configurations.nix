{ config, lib, ... }:
{
  # Generate a NixOS configuration for each device defined under modules/inventory/
  flake.nixosConfigurations = lib.mapAttrs (
    _name: device:
    config.flake.lib.devices.mkSystem {
      deviceTypeName = device.deviceType;
      inherit (device)
        hostName
        authorizedKeys
        facterReport
        modules
        ;
    }
  ) config.devices;
}
