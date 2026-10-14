{ inputs, ... }:
{
  # This is the only module that defines `disko.devices`
  # Everything else sets `storage.device` or `storage.bootPartitions`
  flake.modules.nixos.storage-layout = {
    # Imported from several places; the key makes NixOS load it only once
    key = "storage-layout";
    imports = [
      (
        { config, lib, ... }:
        let
          cfg = config.storage;
        in
        {
          imports = [ inputs.disko.nixosModules.disko ]; # Declarative disk partitioning

          options.storage = {
            device = lib.mkOption {
              type = lib.types.str;
              description = "Block device to install on (prefer /dev/disk/by-id or by-path)";
            };
            bootPartitions = lib.mkOption {
              type = lib.types.attrsOf lib.types.raw;
              default = { };
              description = "Platform-specific partitions (ESP, Raspberry Pi firmware) placed before root";
            };
          };

          # Create separate BTRFS subvolumes for /root, /nix, and /persist
          config = {
            disko.devices.disk.main = {
              type = "disk";
              device = cfg.device;
              content = {
                type = "gpt";
                partitions = cfg.bootPartitions // {
                  root = {
                    name = "root";
                    size = "100%";
                    content = {
                      type = "btrfs";
                      extraArgs = [ "-f" ];
                      subvolumes = {
                        "/root" = {
                          mountpoint = "/";
                          mountOptions = [
                            "compress=zstd"
                            "noatime"
                          ];
                        };
                        "/nix" = {
                          mountpoint = "/nix";
                          mountOptions = [
                            "compress=zstd"
                            "noatime"
                          ];
                        };
                        "/persist" = {
                          mountpoint = "/persist";
                          mountOptions = [
                            "compress=zstd"
                            "noatime"
                          ];
                        };
                      };
                    };
                  };
                };
              };
            };
            fileSystems."/persist".neededForBoot = true;
          };
        }
      )
    ];
  };
}
