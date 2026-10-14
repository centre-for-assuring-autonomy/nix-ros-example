{ self, inputs, ... }:
{
  # Ephemeral root filesystem + rollback via BTRFS subvolumes
  flake.modules.nixos.storage-impermanence = {
    # Imported from several places; the key makes NixOS load it only once
    key = "storage-impermanence";
    imports = [
      (
        {
          config,
          pkgs,
          utils,
          ...
        }:
        let
          # Resolved by disko from modules/storage/layout.nix (the "root" partition)
          rootDev = config.disko.devices.disk.main.content.partitions.root.device;
          rootDevUnit = "${utils.escapeSystemdPath rootDev}.device";
        in
        {
          imports = [ inputs.impermanence.nixosModules.impermanence ];

          boot.initrd.systemd.enable = true;
          boot.initrd.supportedFilesystems = [ "btrfs" ];

          # Rollback service that implements ephemeral root filesystem
          boot.initrd.systemd.services.rollback-root = {
            description = "Rollback btrfs root subvolume to a pristine state";
            wantedBy = [ "initrd.target" ];
            requires = [ rootDevUnit ];
            after = [ rootDevUnit ];
            before = [ "sysroot.mount" ];
            unitConfig.DefaultDependencies = "no";
            serviceConfig = {
              Type = "oneshot";
              StandardOutput = "journal+console";
              StandardError = "journal+console";
            };
            script = ''
              set -eu

              mnt=/btrfs_tmp
              mkdir -p "$mnt"
              mount -o subvol=/ ${rootDev} "$mnt"

              # No hardware real-time clock on a Raspberry Pi, so initrd doesn't know the time
              # Restore the last known time from systemd-timesyncd's state file instead
              clock="$mnt/persist/var/lib/systemd/timesync/clock"

              if [ -e "$clock" ]; then
                saved=$(stat -c %Y "$clock")
                now=$(date +%s)
                if [ "$saved" -gt "$now" ]; then
                  date -s "@$saved" || true
                fi
              fi

              # Store copies of old roots instead of deleting them immediately
              budget_kib=$((512 * 1024))   # Keep old_roots under ~512 MiB
              min_keep=3                   # Keep at least this many previous roots

              if [ -e "$mnt/root" ]; then
                mkdir -p "$mnt/old_roots"
                subvol_id=$(btrfs inspect-internal rootid "$mnt/root")
                last_modified=$(date --date="@$(stat -c %Y "$mnt/root")" "+%Y-%m-%d_%H:%M:%S")
                mv "$mnt/root" "$mnt/old_roots/$(printf '%06d' "$subvol_id")_$last_modified"
              fi

              # Delete oldest root first until under budget, but always keep min_keep
              set -- "$mnt"/old_roots/[0-9]*

              if [ -e "$1" ]; then
                count=$#
                total=$(du -sk "$mnt/old_roots" | cut -f 1)

                for old in "$@"; do
                  [ "$total" -le "$budget_kib" ] && break
                  [ "$count" -le "$min_keep" ] && break

                  size=$(du -sk "$old" | cut -f 1)

                  if btrfs subvolume delete -R "$old" >/dev/null; then
                    total=$((total - size)); count=$((count - 1))
                  else
                    echo "Warning: could not delete $old"
                  fi
                done
              fi

              btrfs subvolume create "$mnt/root"
              umount "$mnt"
            '';
          };

          # Persist files and directories that need to survive rebooting
          environment.persistence."/persist" = {
            hideMounts = true;
            directories = [
              "/var/log"
              "/var/lib/nixos"
              "/var/lib/systemd/coredump"
              "/var/lib/systemd/timesync"
              "/var/lib/NetworkManager"
              "/etc/NetworkManager/system-connections"
            ];
            files = [
              "/etc/machine-id"
            ];
            users.robot.directories = [
              ".local/share"
            ];
          };

          environment.systemPackages = [ pkgs.btrfs-progs ]; # For inspecting `old_roots`
        }
      )
    ];
  };
}
