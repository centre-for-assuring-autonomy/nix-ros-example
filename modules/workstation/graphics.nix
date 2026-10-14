{ self, inputs, ... }:
let
  # The NVIDIA driver is unfree, so it needs its own nixpkgs instance with allowUnfree
  nvidiaPkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    config = {
      allowUnfree = true;
      nvidia.acceptLicense = true;
    };
  };

  # NVIDIA driver libraries
  mkNvidiaLibs =
    { version, sha256_64bit }:
    (nvidiaPkgs.linuxPackages.nvidiaPackages.mkDriver {
      inherit version sha256_64bit;
      useSettings = false;
      usePersistenced = false;
    }).override
      { libsOnly = true; };
in
{
  # Userspace graphics drivers for non-NixOS hosts
  # Needed for Nix-built GL apps (e.g. rviz2 in the dev shell) to render correctly
  flake.modules.systemManager.graphics =
    { config, lib, ... }:
    let
      nvidia = config.graphics.nvidia;
      useNvidia = nvidia.version != null;
    in
    {
      imports = [ inputs.nix-system-graphics.systemModules.default ];

      options.graphics.nvidia = {
        version = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            Must match the host's kernel driver version (check with `cat /proc/driver/nvidia/version`)
            Leave null for hosts without an NVIDIA GPU (Mesa only)
          '';
          example = "615.78.08";
        };
        sha256_64bit = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "SRI hash of the 64-bit NVIDIA .run installer for `version`";
        };
      };

      config = {
        assertions = [
          {
            assertion = (nvidia.version == null) == (nvidia.sha256_64bit == null);
            message = "graphics.nvidia.version and graphics.nvidia.sha256_64bit must be set together.";
          }
        ];

        nixpkgs.hostPlatform = "x86_64-linux";
        system-manager.allowAnyDistro = true;
        system-graphics.enable = true;

        # Only override the package when an NVIDIA version was given;
        # otherwise the module's default (Mesa) package is used
        system-graphics.package =
          if useNvidia then
            mkNvidiaLibs { inherit (nvidia) version sha256_64bit; }
          else
            inputs.nixpkgs.legacyPackages.x86_64-linux.mesa;
      };
    };
}
