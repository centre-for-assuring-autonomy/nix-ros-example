{ deploy-rs, nixpkgs }:
[
  deploy-rs.overlays.default

  # Take the deploy-rs binary from plain nixpkgs (cache.nixos.org),
  # but keep the flake's `lib` for activation helpers
  (self: super: {
    deploy-rs = {
      inherit (nixpkgs.legacyPackages.${self.stdenv.hostPlatform.system}) deploy-rs;
      lib = super.deploy-rs.lib;
    };
  })
]
