{
  config,
  lib,
  ...
}:
{
  options.devices = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            deviceType = lib.mkOption {
              type = lib.types.enum (lib.attrNames config.deviceTypes);
            };
            hostName = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            ip = lib.mkOption { type = lib.types.str; };
            authorizedKeys = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ config.keys.deployer ];
            };
            modules = lib.mkOption {
              # Per-instance extras (wifi, ROS namespace, etc)
              type = lib.types.listOf lib.types.raw;
              default = [ ];
            };
            facterReport = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "Overrides the device type's nixos-facter report for this device";
            };
          };
        }
      )
    );
  };
}
