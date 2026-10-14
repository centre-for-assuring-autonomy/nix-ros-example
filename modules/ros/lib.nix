{ config, inputs, ... }:
let
  inherit (inputs) nixpkgs nix-ros-overlay;

  # Overlay that patches nix-ros-overlay packages
  rosFixes = import ../../overlays/ros-fixes.nix;

  # Apply the package overlay to a given profile
  rosOverlayFor = profile: final: prev: {
    rosPackages =
      (import nixpkgs {
        system = final.stdenv.hostPlatform.system;
        overlays = [
          nix-ros-overlay.overlays.default
          rosFixes
        ]
        ++ config.ros.profiles.${profile}.overlays;
      }).rosPackages;
  };

  # nixpkgs with the overlay applied to the given profile + system
  pkgsFor =
    profile: system:
    import nixpkgs {
      inherit system;
      overlays = [ (rosOverlayFor profile) ];
    };

  # ROS environment for a given profile + system
  rosEnvFor =
    profile: system:
    import ./_ros-env.nix {
      pkgs = pkgsFor profile system;
      profile = config.ros.profiles.${profile};
    };
in
{
  flake.lib.ros = { inherit rosOverlayFor pkgsFor rosEnvFor; };
}
