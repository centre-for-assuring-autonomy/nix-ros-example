{ config, lib, ... }:
let
  # Resolves a device type name to its builder and full NixOS module list
  mkResolveDeviceType =
    {
      compute,
      disks,
      robots,
      deviceTypes,
      virtualModule,
    }:
    deviceTypeName:
    let
      deviceType = deviceTypes.${deviceTypeName};
      computeDef = compute.${deviceType.compute};
      diskDef = disks.${deviceType.disk};
      robotDef = if deviceType.robot == null then null else robots.${deviceType.robot};
    in
    assert lib.assertMsg (deviceType.virtual -> computeDef.supportsVirtual)
      "deviceType '${deviceTypeName}': compute platform '${deviceType.compute}' does not support virtual = true";
    assert lib.assertMsg (diskDef.virtual == deviceType.virtual)
      "deviceType '${deviceTypeName}': disk '${deviceType.disk}' is ${
        lib.optionalString (!diskDef.virtual) "not "
      }virtual, but the device type has virtual = ${lib.boolToString deviceType.virtual}";
    # Virtual device types skip this check: their disk is virtual, which no physical compute lists
    assert lib.assertMsg (deviceType.virtual || lib.elem deviceType.disk computeDef.supportedDisks)
      "deviceType '${deviceTypeName}': disk '${deviceType.disk}' is not supported on compute platform '${deviceType.compute}' (supported: ${lib.concatStringsSep ", " computeDef.supportedDisks})";
    {
      inherit (computeDef) builder;
      inherit (deviceType) facterReport kind;
      # Virtual devices need no hardware report: the qemu-guest profile covers the hardware
      requiresFacter = computeDef.requiresFacter && !deviceType.virtual;
      modules = [
        computeDef.module
      ]
      ++ lib.optional deviceType.virtual virtualModule
      ++ [ diskDef.module ]
      ++ lib.optionals (robotDef != null) [
        robotDef.module
        { ros.profile = robotDef.rosProfile; } # Devices without a robot keep the `base` default
      ]
      ++ deviceType.extraModules;
    };

  # Resolved view of a device type
  resolveDeviceType = mkResolveDeviceType {
    inherit (config)
      compute
      disks
      robots
      deviceTypes
      ;
    virtualModule = config.flake.modules.nixos.virtual-qemu;
  };

  # The device's own nixos-facter report wins over the device type's (null if neither has one)
  facterReportFor =
    {
      deviceTypeName,
      facterReport ? null,
    }:
    lib.defaultTo (resolveDeviceType deviceTypeName).facterReport facterReport;

  # null until the report has been generated and tracked via git
  reportIfPresent = path: if builtins.pathExists path then path else null;

  # Builds a NixOS system from a device type plus per-instance values
  mkSystem =
    {
      deviceTypeName,
      hostName,
      authorizedKeys ? [ ],
      facterReport ? null,
      modules ? [ ],
    }:
    let
      resolved = resolveDeviceType deviceTypeName;
      report = facterReportFor { inherit deviceTypeName facterReport; };
    in
    resolved.builder {
      modules = [
        config.flake.modules.nixos.system
        config.flake.modules.nixos.ros
        {
          networking.hostName = hostName;
          ros.kind = resolved.kind;
          users.users = lib.genAttrs [ "root" "robot" ] (_: {
            openssh.authorizedKeys.keys = authorizedKeys;
          });
        }
      ]
      ++ lib.optional (report != null) { hardware.facter.reportPath = report; }
      # A missing report is only a warning here - deploy.nix refuses to deploy without one
      ++ lib.optional (resolved.requiresFacter && report == null) {
        warnings = [
          "'${hostName}': compute platform requires a nixos-facter report; set facterReport on device type '${deviceTypeName}' or on the device"
        ];
      }
      ++ resolved.modules
      ++ modules;
    };
in
{
  config.flake.lib.devices = {
    inherit
      mkResolveDeviceType
      resolveDeviceType
      reportIfPresent
      facterReportFor
      mkSystem
      ;
  };
}
