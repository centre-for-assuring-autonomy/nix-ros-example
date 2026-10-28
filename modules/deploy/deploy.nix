{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (inputs) nixpkgs deploy-rs;
  inherit (config.flake.lib.devices) resolveDeviceType facterReportFor;

  nodeSystem = name: config.flake.nixosConfigurations.${name}.config.nixpkgs.hostPlatform.system;

  # The deploy nodes that belong to a given system
  nodesFor = system: lib.filterAttrs (name: _: nodeSystem name == system) inputs.self.deploy.nodes;

  # `nixpkgs` overlay for `deploy-rs`
  deployPkgsFor =
    system:
    import nixpkgs {
      inherit system;
      overlays = import ../../overlays/deploy-rs.nix { inherit deploy-rs nixpkgs; };
    };

  # A device can only be deployed if its compute platform's nixos-facter hardware report requirement is met
  isDeployable =
    device:
    !(resolveDeviceType device.deviceType).requiresFacter
    ||
      facterReportFor {
        deviceTypeName = device.deviceType;
        inherit (device) facterReport;
      } != null;
in
{
  config.flake = {
    # Generate a `deploy-rs` deployment node for each deployable device
    # Devices missing a nixos-facter report are skipped (but still evaluated via nixosConfigurations)
    deploy.nodes = lib.mapAttrs (
      name: device:
      let
        nixos-configuration = config.flake.nixosConfigurations.${name};
      in
      {
        hostname = device.ip;
        sshUser = "root";
        # Using the `deploy-rs` overlay format to take advantage of the `nixpkgs` binary cache
        profiles.system.path = (deployPkgsFor nixos-configuration.config.nixpkgs.hostPlatform.system).deploy-rs.lib.activate.nixos nixos-configuration;
      }
    ) (lib.filterAttrs (_: isDeployable) config.devices);

    # Allows `nix flake check` to validate `deploy-rs` deployment expressions
    # Only systems that have deploy nodes get checks (deploy-rs.lib also lists darwin systems,
    # which fail to evaluate on nixpkgs releases that dropped x86_64-darwin)
    checks = lib.mapAttrs (
      system: deployLib: deployLib.deployChecks (inputs.self.deploy // { nodes = nodesFor system; })
    ) (lib.filterAttrs (system: _: nodesFor system != { }) deploy-rs.lib);
  };

  # `nix run .#deploy-rs` uses the nixpkgs build of the CLI pinned by flake.lock
  config.perSystem =
    { system, ... }:
    {
      packages.deploy-rs = nixpkgs.legacyPackages.${system}.deploy-rs;
    };
}
