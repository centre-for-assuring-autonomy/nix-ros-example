{
  self,
  inputs,
  lib,
  ...
}:
let
  # nix-system-graphics configurations for different workstations
  workstations = {
    hp-zbook = {
      version = "615.78.08";
      sha256_64bit = "sha256-Pj9t3cLudnoIGFMAr3vjyyhuznZpjS3eNSRZl4LQf/4=";
    };
    xnuc = {
      version = "595.99.02";
      sha256_64bit = "sha256-6HR3lYv3YwcFSTJL1a1slI66btIQ5EAFs+/4SUD24ew=";
    };
    mesa = { };
  };
in
{
  flake.systemConfigs = lib.mapAttrs (
    _name: nvidia:
    inputs.system-manager.lib.makeSystemConfig {
      modules = [
        self.modules.systemManager.graphics
        { graphics.nvidia = nvidia; }
      ];
    }
  ) workstations;
}
