{
  config,
  lib,
  ...
}:
let
  top = config; # Flake-level config; the submodule's own `config` shadows it below
in
{
  options.deviceTypes = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options = {
            compute = lib.mkOption { type = lib.types.enum (lib.attrNames top.compute); };
            disk = lib.mkOption { type = lib.types.enum (lib.attrNames top.disks); };
            robot = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum (lib.attrNames top.robots));
              default = null;
            };
            virtual = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Run as a QEMU guest: adds the virtual-qemu module, requires a virtual disk, and waives the nixos-facter report";
            };
            extraModules = lib.mkOption {
              type = lib.types.listOf lib.types.raw;
              default = [ ];
            };
            facterReport = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "nixos-facter report shared by all devices of this type";
            };
            kind = lib.mkOption {
              type = lib.types.enum [
                "robot"
                "dev"
              ];
              readOnly = true;
              default = if config.robot != null then "robot" else "dev";
              description = "Derived: `robot` if the device type has a robot (on-board computer), otherwise `dev`";
            };
          };
        }
      )
    );
  };
}
