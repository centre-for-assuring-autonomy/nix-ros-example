{ ... }:
{
  flake.modules.nixos.system = {
    services.openssh = {
      enable = true;
      hostKeys = [
        {
          path = "/persist/etc/ssh/ssh_host_ed25519_key"; # Persist SSH host keys
          type = "ed25519";
        }
      ];
    };
  };
}
