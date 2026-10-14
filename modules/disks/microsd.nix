{ config, ... }:
{
  disks.microsd = {
    virtual = false;
    module = config.flake.modules.nixos.disk-microsd;
  };

  flake.modules.nixos.disk-microsd = {
    storage.device = "/dev/disk/by-path/platform-fe340000.mmc";

    # /var/log is persisted, so keep journald in RAM to minimise writes to the card
    services.journald.extraConfig = ''
      Storage=volatile
      RuntimeMaxUse=64M
    '';

    # Configure NixOS garbage collection
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    nix.settings.auto-optimise-store = true;
  };
}
