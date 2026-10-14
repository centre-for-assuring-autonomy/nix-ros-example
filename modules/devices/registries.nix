{
  config,
  inputs,
  lib,
  ...
}:
{
  # Each compute platform is defined by its `builder`, `supportedDisks` and NixOS `module`
  options.compute = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          builder = lib.mkOption {
            type = lib.types.raw;
            default = inputs.nixpkgs.lib.nixosSystem;
          };
          supportedDisks = lib.mkOption {
            type = lib.types.listOf (lib.types.enum (lib.attrNames config.disks));
          };
          supportsVirtual = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether device types on this compute platform may set `virtual = true`";
          };
          requiresFacter = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether devices on this compute platform need a nixos-facter report";
          };
          module = lib.mkOption {
            type = lib.types.deferredModule;
            description = "NixOS module configuring this compute platform (also exported as flake.modules.nixos.compute-<name>)";
          };
        };
      }
    );
  };

  # Where the OS lives: each disk is defined by its NixOS `module` and whether it is virtual
  options.disks = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          virtual = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether this is a virtual disk (valid only on virtual device types, and vice versa)";
          };
          module = lib.mkOption {
            type = lib.types.deferredModule;
            description = "NixOS module configuring this disk (also exported as flake.modules.nixos.disk-<name>)";
          };
        };
      }
    );
  };

  # Robot hardware integration: each robot is defined by its ROS profile and NixOS `module`
  options.robots = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          rosProfile = lib.mkOption {
            type = lib.types.enum (lib.attrNames config.ros.profiles);
            description = "Entry of ros.profiles that devices with this robot run";
          };
          module = lib.mkOption {
            type = lib.types.deferredModule;
            description = "NixOS module for this robot's hardware integration (also exported as flake.modules.nixos.robot-<name>)";
          };
        };
      }
    );
  };
}
