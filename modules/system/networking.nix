{ ... }:
{
  flake.modules.nixos.system = {
    networking = {
      enableIPv6 = false;
      firewall.logRefusedPackets = true;
    };
  };
}
