# Remotely deploying NixOS + ROS 2 to a robot

Initial deployment via [`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere):

```
nix run github:nix-community/nixos-anywhere -- \
--flake .#robot-onboard-pc \
--target-host nixos@192.168.68.150 \
--generate-hardware-config nixos-generate-config ./hardware-configuration.nix
```

Subsequent deployments via [`deploy-rs`](https://github.com/serokell/deploy-rs):

```
nix run nixpkgs#deploy-rs -- .#robot-onboard-pc
```
