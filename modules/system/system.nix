{ self, ... }:
{
  flake.modules.nixos.system =
    { pkgs, ... }:
    {
      # Ephemeral root filesystem + rollback via BTRFS subvolumes
      imports = [ self.modules.nixos.storage-impermanence ];

      # Useful non-ROS packages installed system-wide
      environment.systemPackages = with pkgs; [
        curl
        file
        git
        htop
        kitty # Installs terminfo files
        net-tools
        ripgrep
        tree
        usbutils
        vim
        wget
      ];

      # Set timezone and locale
      time.timeZone = "Europe/London";
      i18n.defaultLocale = "en_GB.UTF-8";

      # NixOS release
      system.stateVersion = "26.05";
    };
}
