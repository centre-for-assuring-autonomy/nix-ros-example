{ lib, ... }:
{
  options.keys = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
  };

  # Public SSH keys of machines used to deploy NixOS via `nixos-anywhere` / `deploy-rs`
  config.keys.deployer = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFc3B4+NkLE7wwxzqGMYLH44hThx0LGw7VbXzSmmuiM7";
  config.keys.xnuc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAd2whqF4VqQtxPxdJr3ekbj8Xx6kQiutfDdZ5Y8uinm";
}
