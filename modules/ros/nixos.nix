{
  config,
  inputs,
  self,
  ...
}:
let
  outer = config; # flake-parts config; the inner `config` is NixOS's
  rosLib = outer.flake.lib.ros; # Provides the helper function rosOverlayFor

  # Add `nix-ros-overlay` binary caches to NixOS
  rosCaches = with outer.caches; [
    ros
    ros-experimental
  ];
in
{
  flake.modules.nixos.ros =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # ROS environment tailored to a given profile
      rosEnv = import ./_ros-env.nix {
        inherit pkgs;
        profile = outer.ros.profiles.${config.ros.profile};
      };

      # Calculate FastDDS base port based on ROS_DOMAIN_ID
      # https://docs.ros.org/en/jazzy/Concepts/Intermediate/About-Domain-ID.html
      fastdds_base_port = 7400 + (250 * rosEnv.domainId);
    in
    {
      imports = [
        inputs.nix-ros-overlay.nixosModules.default # NixOS module provided by nix-ros-overlay
        self.modules.nixos.storage-impermanence # Ephemeral root filesystem + rollback via BTRFS subvolumes
      ];

      # Whether this machine is a robot's on-board computer or a development machine
      # Set by mkSystem from the device type's derived `kind`
      options.ros.kind = lib.mkOption {
        type = lib.types.enum [
          "robot"
          "dev"
        ];
        description = "Selects robotPackages (robot) or devPackages (dev)";
      };

      # Which entry of ros.profiles this machine runs
      options.ros.profile = lib.mkOption {
        type = lib.types.enum (lib.attrNames outer.ros.profiles);
        default = "base";
      };

      # NixOS configuration
      config = {
        # nixpkgs + ROS package overlay for this profile
        nixpkgs.overlays = [ (rosLib.rosOverlayFor config.ros.profile) ];

        # Binary caches for nix-ros-overlay
        nix.settings = {
          extra-substituters = map (cache: cache.url) rosCaches;
          extra-trusted-public-keys = map (cache: cache.key) rosCaches;
        };

        # NixOS module provided by nix-ros-overlay, configured with the rosEnv for this profile
        services.ros2 = {
          enable = true;
          distro = rosEnv.distro;
          domainId = rosEnv.domainId;
          systemPackages = if config.ros.kind == "robot" then rosEnv.robotPackages else rosEnv.devPackages;
        };

        # Set environment variables based on rosEnv.envVars, except for ROS_DOMAIN_ID
        # ROS_DOMAIN_ID is exported by nix-ros-overlay (set via services.ros2.domainId)
        environment.sessionVariables = removeAttrs rosEnv.envVars [ "ROS_DOMAIN_ID" ];

        # Persist ROS-specific directories
        environment.persistence."/persist".users.robot.directories = [
          "ros_ws"
          "rosbags"
          ".ros"
        ];

        # Register python-argcomplete in interactive shells
        programs.bash.interactiveShellInit = rosEnv.argcompleteInit;

        # Configure NixOS firewall
        networking.firewall = {
          allowedUDPPorts = [ 49150 ]; # ros2 multicast send/receive

          # FastDDS port ranges for 120 participants (maximum value)
          # ROS_DOMAIN_ID=0:   7400:7649
          # ROS_DOMAIN_ID=30: 14900:15149
          allowedUDPPortRanges = [
            {
              from = fastdds_base_port;
              to = fastdds_base_port + 249;
            }
            {
              from = 7000;
              to = 7100;
            } # Fast DDS unique-flow ports
          ];
        };
      };
    };
}
