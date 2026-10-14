{ ... }:
{
  flake.modules.nixos.system = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "robot" ];
    };
  };
}
