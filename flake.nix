{
  inputs = {
    # ROS package overlay
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";

    # nix-ros-overlay is cached against a specific version of nixpkgs
    # Using the same version of nixpkgs for most other things
    nixpkgs.follows = "nix-ros-overlay/nixpkgs";

    # Raspberry Pi support for NixOS
    # Should not follow nix-ros-overlay/nixpkgs, otherwise kernel cache will be invalidated
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    # Declarative disk partitioning
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs";

    # Recursively imports Nix modules from a directory
    # Skips /_ prefixed paths
    import-tree.url = "github:denful/import-tree";

    # Used to split Nix flake into Nix modules
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # Remote deployment of Nix flake (after initial deployment via nix-community/nixos-anywhere)
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    # Used to create ephemeral root filesystem
    impermanence.url = "github:nix-community/impermanence";
    # Remove dependencies used for internal development
    impermanence.inputs.nixpkgs.follows = "";
    impermanence.inputs.home-manager.follows = "";

    # Used to configure non-NixOS Linux distributions via Nix
    # Needed for installing nix-system-graphics
    system-manager.url = "github:numtide/system-manager";

    # Used to run GPU-accelerated programs (e.g. RViz) on non-NixOS Linux distributions
    # Fork of soupglasses/nix-system-graphics for proprietary NVIDIA drivers
    nix-system-graphics.url = "github:wentasah/nix-system-graphics/nvidia-update";
    nix-system-graphics.inputs.nixpkgs.follows = "nixpkgs";
  };
  # flake-parts + import-tree used to split Nix flake into modules
  # Recursively imports Nix modules in ./modules directory
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  # Binary caches for nix-ros-overlay and nixos-raspberrypi
  # Must be a literal (Nix reads it before evaluation) - keep in sync with modules/nix/caches.nix
  nixConfig = {
    extra-substituters = [
      "https://ros.cachix.org"
      "https://attic.iid.ciirc.cvut.cz/ros"
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
      "ros:JR95vUYsShSqfA1VTYoFt1Nz6uXasm5QrcOsGry9f6Q="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };
}
