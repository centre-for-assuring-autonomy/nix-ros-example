{
  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "";
    impermanence.inputs.home-manager.follows = "";
  };

  outputs = { self, nixpkgs, disko, deploy-rs, nix-ros-overlay, impermanence, ... }:
    let
      overlays = [ nix-ros-overlay.overlays.default ];
      pkgs = import nixpkgs { system = "x86_64-linux"; inherit overlays; };

      common = import ./ros-common.nix { inherit pkgs; };

      defaultTarget = "robot-onboard-pc";

      mkDevShell = name:
        pkgs.mkShell ({
          name = "devshell-${name}";
          packages = [
              common.devRosEnv
              pkgs.colcon
              pkgs.libcanberra-gtk3
            ];
          shellHook = ''
            ${common.argcompleteInit}
          '';
        } // common.envVars);

      targets = {
        robot-onboard-pc = {
          ip = "192.168.68.150";
          sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFc3B4+NkLE7wwxzqGMYLH44hThx0LGw7VbXzSmmuiM7";
        };
      };
    in
    {
      devShells.x86_64-linux =
        nixpkgs.lib.mapAttrs (name: _: mkDevShell name) targets
        // { default = mkDevShell defaultTarget; };

      nixosModules.default = { ... }: {
        imports = [ nix-ros-overlay.nixosModules.default ];
        nixpkgs.overlays = overlays;
      };

      nixosConfigurations = nixpkgs.lib.mapAttrs (name: target:
        nixpkgs.lib.nixosSystem {
          specialArgs = { 
            inherit common;
          };
          modules = [
            self.nixosModules.default  # ROS module + overlays
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            ./configuration.nix
            ./hardware-configuration.nix
            {
              networking.hostName = "robot-hostname";
              users.users = nixpkgs.lib.genAttrs [ "root" "robot" ] (_user: {
                openssh.authorizedKeys.keys = [ target.sshKey ];
              });
            }
          ];
        }
      ) targets;

      deploy.nodes = nixpkgs.lib.mapAttrs (name: target: {
        hostname = target.ip;
        user = "root";
        sshUser = "root";
        profiles.system = {
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.${name};
        };
      }) targets;

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };

  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
  };
}
