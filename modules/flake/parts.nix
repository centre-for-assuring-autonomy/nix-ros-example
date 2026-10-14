{ inputs, lib, ... }:
{
  # Make the flake.modules.nixos.* namespace available to other modules
  imports = [ inputs.flake-parts.flakeModules.modules ];

  # Helper functions shared between modules
  # Two levels of attrsOf, so several files can contribute to the same namespace
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
    default = { };
  };

  config = {
    # https://flake.parts/debug.html
    debug = true;

    # System architectures passed to flake-parts perSystem
    systems = [ "x86_64-linux" ]; # Only used in modules/flake/devshells.nix
  };
}
