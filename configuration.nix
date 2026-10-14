{
  common,
  config,
  lib,
  modulesPath,  
  pkgs,
  utils,
  ...
} @ args:
let
  rootDev = config.disko.devices.disk.disk1.content.partitions.root.device;
  rootDevUnit = "${utils.escapeSystemdPath rootDev}.device";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://ros.cachix.org" ];
    trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
    extra-substituters = [ "https://attic.iid.ciirc.cvut.cz/ros" ];
    extra-trusted-public-keys = [ "ros:JR95vUYsShSqfA1VTYoFt1Nz6uXasm5QrcOsGry9f6Q=" ];
    trusted-users = [ "robot" ];
  };

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = [ "nodev" ];
  };

  boot.initrd.systemd.services.rollback-root = {
    description = "Rollback btrfs root subvolume to a pristine state";
    wantedBy = [ "initrd.target" ];
    requires = [ rootDevUnit ];
    after = [ rootDevUnit ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    path = with pkgs; [ btrfs-progs coreutils findutils util-linux ];
    script = ''
      # From: https://github.com/nix-community/impermanence/blob/master/README.org#btrfs-subvolumes
      mkdir -p /btrfs_tmp
      mount ${rootDev} /btrfs_tmp

      if [[ -e /btrfs_tmp/root ]]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
          mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
      fi

      delete_subvolume_recursively() {
          IFS=$'\n'
          for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
              delete_subvolume_recursively "/btrfs_tmp/$i"
          done
          btrfs subvolume delete "$1"
      }

      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
          delete_subvolume_recursively "$i"
      done

      btrfs subvolume create /btrfs_tmp/root
      umount /btrfs_tmp
    '';
  };

  # Register python-argcomplete in interactive shells and persist bash history
  programs.bash = {
    completion.enable = true;
    interactiveShellInit = ''
      ${common.argcompleteInit}
      export HISTFILE="$HOME/.local/state/bash/history"
      export HISTSIZE=10000
      export HISTFILESIZE=100000
      # Append after every command, not only at shell exit
      shopt -s histappend
      PROMPT_COMMAND="history -a''${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
    '';
    };

  services.ros2 = {
    enable = true;
    distro = common.distro;
    systemPackages = p: common.sharedPackages p ++ common.robotPackages p;
  };

  # SSH host keys must survive reboots, or deploy-rs/ssh will see a new
  # host key every time. Point directly at /persist (available early in boot)
  services.openssh = {
    enable = true;
    hostKeys = [{
      path = "/persist/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/NetworkManager"
      "/etc/NetworkManager/system-connections"
    ];
    files = [
      "/etc/machine-id"
    ];
    users.robot.directories = [
      ".local/share"
      ".local/state/bash"
      "ros_ws"
      "rosbags"
      ".ros"
    ];
  };

  environment.systemPackages = with pkgs; [
    curl
    file
    git
    htop
    kitty
    net-tools
    ripgrep
    tree
    usbutils
    vim
    wget
  ];

  users = {
    mutableUsers = false;
    users."robot" = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" ];
      password = "password";
    };
  };

  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';

  networking = {
    enableIPv6 = false;
  };

  system.stateVersion = "26.05";
}
