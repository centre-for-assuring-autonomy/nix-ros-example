{ ... }:
{
  flake.modules.nixos.system = {
    users = {
      mutableUsers = false;
      # Non-root user
      users."robot" = {
        isNormalUser = true;
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        # Simple plaintext password example
        # Use hashed password or key-only access instead for security
        password = "password";
      };
    };

    # Disable sudo security lecture - will otherwise be prompted after every reboot
    # due to ephemeral root filesystem (unless additional state is persisted)
    security.sudo.extraConfig = ''
      Defaults lecture = never
    '';
  };
}
