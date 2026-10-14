{ config, lib, ... }:
let
  # Provides the helper functions pkgsFor + rosEnvFor
  rosLib = config.flake.lib.ros;
in
{
  # flake-parts evaluates this for each system architecture defined in modules/flake/parts.nix
  perSystem =
    { system, ... }:
    let
      # Development shell for a given profile + system
      mkDevShell =
        profile:
        let
          pkgs = rosLib.pkgsFor profile system; # nixpkgs + rosOverlayFor this profile + system
          rosEnv = rosLib.rosEnvFor profile system; # ROS environment for this profile + system
        in
        pkgs.mkShell (
          {
            name = "devshell-${profile}-${system}";
            packages = [
              rosEnv.devRosEnv # ROS packages needed for development environment
              pkgs.colcon
              pkgs.libcanberra-gtk3
              pkgs.deploy-rs
            ];
            shellHook = rosEnv.argcompleteInit; # bash argument completion for ros2 and colcon commands
          }
          // rosEnv.envVars # Merge in ROS environment variables
        );
    in
    {
      # For each ROS profile, generate a corresponding development shell as a flake output
      devShells = lib.mapAttrs (profile: _: mkDevShell profile) config.ros.profiles // {
        default = mkDevShell "base"; # Merge in dev shell created for the base profile as the default
      };
    };
}
