{ lib, ... }:
{
  options.caches = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          url = lib.mkOption { type = lib.types.str; };
          key = lib.mkOption { type = lib.types.str; };
        };
      }
    );
    default = { };
  };

  # Binary caches for nix-ros-overlay and nixos-raspberrypi
  # nixos-raspberrypi caches are only used by Raspberry Pi configurations
  config.caches = {
    ros = {
      url = "https://ros.cachix.org";
      key = "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=";
    };
    ros-experimental = {
      url = "https://attic.iid.ciirc.cvut.cz/ros";
      key = "ros:JR95vUYsShSqfA1VTYoFt1Nz6uXasm5QrcOsGry9f6Q=";
    };
    nixos-raspberrypi = {
      url = "https://nixos-raspberrypi.cachix.org";
      key = "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI=";
    };
  };
}
