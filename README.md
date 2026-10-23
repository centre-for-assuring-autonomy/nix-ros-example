# Remotely deploying NixOS + ROS 2

This repository provides example Nix code that allows you to:

- Build *reproducible* operating system images for your robot: NixOS bundled with ROS packages of your choice, as well as any custom infrastructure you might need.
- Remotely deploy and incrementally update these NixOS images to your robot over SSH, with automatic rollback to the last working version if anything fails.
- Enter a Nix development shell on your local workstation, allowing you to run ROS on non-NixOS hosts (e.g. Ubuntu).

You can also build a custom NixOS image that runs on your local workstation in a QEMU virtual machine, for testing/experimentation without access to robot hardware.

## Installing and configuring Nix

Unless your local host machine is running NixOS, you will need to install Nix: https://nixos.org

The following instructions assume that you have installed Nix on an `x86` host machine running Ubuntu 24.04.

> [!IMPORTANT]
> Run `sudo systemctl restart nix-daemon.service` after making changes to your `/etc/nix/nix.conf` Nix configuration

To enable the 'experimental' `nix` command and Nix flakes, add the following to `/etc/nix/nix.conf`. Alternatively, pass `--extra-experimental-features "nix-command flakes"` to Nix commands.

```nix
experimental-features = nix-command flakes
```
Register yourself as a trusted user by running the following command. Alternatively, pass `--accept-flake-config` to Nix commands. If you don't do this, Nix will ignore the binary cache settings in the flake, causing everything to be built from source instead.
```sh
$ echo "trusted-users = $USER" | sudo tee -a /etc/nix/nix.conf
```

You can build NixOS for `aarch64` targets (e.g. Raspberry Pi) on an `x86` host by installing support for emulated builds via QEMU:
```sh
$ sudo apt install binfmt-support qemu-user-static
```
Then add the following lines to `/etc/nix/nix.conf`: 

```nix
extra-platforms = aarch64-linux
extra-sandbox-paths = /usr/bin/qemu-aarch64-static
```
If emulated builds are too slow, you could build natively on an `aarch64` machine, either locally or remotely (`--build-on remote` with `nixos-anywhere`, or `--remote-build` with `deploy-rs`)

## Remote deployment

### Trusted keys

Replace the placeholder key in `modules/deploy/keys.nix` with your own **public** SSH key. You can find your public SSH key by running the following command:
```sh
cat ~/.ssh/id_ed25519.pub
```

`keys.deployer` is installed as an authorised SSH key on every device by default, for the `root` and `robot` users. The machine that you are deploying from must posses the matching **private key**.

### Initial deployment

[`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere) can be used for the initial remote deployment over SSH. It will upload a temporary NixOS installer and boot it from RAM; partition the disk with [`disko`](https://github.com/nix-community/disko); install your custom NixOS build; then reboot the device. 

If your robot is already running a Linux operating that supports `kexec`, `nixos-anywhere` can overwrite the existing OS with NixOS. If you are starting from a clean slate, you can boot your robot's computer from a NixOS installer USB flash drive, then open a terminal and run `passwd` to set the password for the default `nixos` user (to be entered interactively as part of the `nixos-anywhere` deployment process).

For physical `x86` targets, [`nixos-facter`](https://github.com/nix-community/nixos-facter) is used to scan the target device's hardware, and generates a report in JSON format that NixOS uses to configure drivers and kernel modules. This is not necessary when deploying to a Raspberry Pi or virtual machine (`nixos-raspberrypi` / the `qemu-guest` profile handle everything for you).

> [!WARNING]
> Everthing on the corresponding `storage.device` will be erased

```sh
$ nix run github:nix-community/nixos-anywhere -- \
  --flake .#rugged-nuc \
  --target-host nixos@144.32.33.39 \
  --generate-hardware-config nixos-facter ./modules/inventory/dev/rugged-nuc-facter.json \
```
Unfortunately, `nixos-anywhere` cannot overwrite an existing operating system running on a Raspberry Pi (unsupported `kexec` phase must be skipped). Instead, follow these instructions to build a NixOS installer image for your Raspberry Pi model: https://github.com/nvmd/nixos-raspberrypi#installer-configurations-and-configuration-examples

Write this image to a microSD card or USB flash drive, and boot your Raspberry Pi from it while connected to an external monitor. The installer will display a randomly generated `root` password that you can enter interactively as part of the `nixos-anywhere` deployment process: 

```sh
$ nix run github:nix-community/nixos-anywhere -- \
--flake .#turtlebot3-01 \
--target-host root@192.168.68.151 \
--phases disko,install,reboot \
--build-on local
```

### Subsequent deployments

After making changes to the NixOS configuration on your local machine (e.g. adding more ROS packages), you can iteratively deploy these changes over SSH via [`deploy-rs`](https://github.com/serokell/deploy-rs):
```sh
$ nix run nixpkgs#deploy-rs -- .#turtlebot3-01
```

If you SSH into NixOS running on the robot, you can run the following command to display the history of system generations:
```sh
$ nixos-rebuild list-generations
```
The generation number will increment after each successful deployment via `deploy-rs`. If anything fails, `deploy-rs` will automatically rollback to the last working version of NixOS.

If you want to start again from scratch, you can redeploy via `nixos-anywhere` to wipe the disk and install the configuration of NixOS currently defined by the Nix flake.

## Development shell

To open a development shell on your local machine, run one of the following commands:
```sh
# Default shell: ROS 2 + the "base" profile (rviz2, rqt, colcon)
$ nix develop

# A shell matching a specific robot profile (domain ID, environment variables, extra dev packages)
$ nix develop .#turtlebot3
```
The packages installed in the development shell will match the versions installed on the robot, ensuring compatibility.

### GPU drivers on non-NixOS hosts

Graphical programs built by Nix (such as `rviz2`) cannot see your host operating system’s GPU drivers.

`modules/workstation/` provides a `system-manager` configuration that installs matching userspace drivers.

Run the following command to install Mesa drivers:
```sh
$ sudo env PATH=$PATH nix run 'github:numtide/system-manager' -- switch --flake .#mesa
```
If you have an NVIDIA GPU, first find your driver version:
```sh
$ cat /proc/driver/nvidia/version
```
Obtain the driver installer hash by running:
```sh
$ nix-prefetch-url https://download.nvidia.com/XFree86/Linux-x86_64/<version>/NVIDIA-Linux-x86_64-<version>.run
$ nix hash convert --hash-algo sha256 --to sri <output-of-previous-command>
```
Then add your workstation to `modules/workstation/workstations.nix`:
```nix
my-workstation = {
  version = "<driver version>"; # Must match the kernel driver exactly
  sha256_64bit = "sha256-...";  # Hash of the NVIDIA .run installer
};
```
Now you can install the NVIDIA drivers via `system-manager`:
```sh
$ sudo env PATH=$PATH nix run 'github:numtide/system-manager' -- switch --flake .#my-workstation
```

## Local virtual machine

You can run your custom NixOS image in a local virtual machine. Two example virtual devices are provided: `turtlebot3-vm` and `dummy-robot`. They run the NixOS configuration that would be deployed on real hardware, including the BTRFS layout and impermanence, inside QEMU.

### Host configuration

The VM connects to the host through a bridge named `br0`. The VM definition hard-codes the guest network: IP `192.168.100.2/24`, a multicast route for ROS discovery, and QEMU's bridge helper at `/usr/lib/qemu/qemu-bridge-helper`. To configure your host to support this configuration, run the following commands:

```sh
# QEMU's bridge helper and KVM acceleration
sudo apt install qemu-system-x86 qemu-system-common
sudo usermod -aG kvm "$USER"            # Log out and in again afterwards
ls -l /usr/lib/qemu/qemu-bridge-helper  # Should be setuid root (-rws...)

# Allow the helper to attach to br0
sudo mkdir -p /etc/qemu
echo 'allow br0' | sudo tee /etc/qemu/bridge.conf

# Create the bridge with a host-side address in the VM's subnet
sudo ip link add br0 type bridge
sudo ip addr add 192.168.100.1/24 dev br0
sudo ip link set br0 up

# Let ROS multicast discovery reach the VM
sudo ip route add 224.0.0.0/4 dev br0

# Add a firewall rule to allow incoming traffic over the bridge
sudo ufw allow in on br0
```

The custom route will send **all** multicast traffic out of `br0` - if this causes any problems, you can remove it by running `sudo ip route del 224.0.0.0/4 dev br0`.

### Dummy robot demo

This repository includes example code for running the dummy robot demo from the ROS 2 documentation: https://docs.ros.org/en/jazzy/Tutorials/Demos/dummy-robot-demo.html

Build and run the virtual machine by running the following command:

```sh
QEMU_KERNEL_PARAMS=console=ttyS0 nix run .#nixosConfigurations.dummy-robot.config.system.build.vmWithDisko -- -nographic
```
After logging in as the `robot` user with the default password (`password`), launch the dummy robot demo: 
```sh
[robot@dummy-robot:~]$ ros2 launch dummy_robot_bringup dummy_robot_bringup_launch.py
```
On your local machine, open the `dummy-robot` development shell:
```sh
$ nix develop .#dummy-robot
```
You should then be able to see the ROS topics being published by the virtual machine:
```sh
$ ros2 topic list
/joint_states
/map
/parameter_events
/robot_description
/rosout
/scan
/tf
/tf_static
```
You can visualise these topics by launching RViz from the development shell:
```sh
$ rviz2 -d modules/inventory/robots/dummy-robot.rviz
```

# Nix code structure

This code follows the [dendritic pattern](https://github.com/Doc-Steve/dendritic-design-with-flake-parts), using `flake-parts` to split the Nix flake into reusable parts and `import-tree` to recursively import files in the `modules/` directory.

The `flake.modules.nixos` namespace is used internally to compose modules that are then merged into the Nix flake's outputs by importing `flake-parts.flakeModules.modules`. 

Files are organised by 'concept', and one file typically contains everything about that concept (for example `compute/rpi4.nix` holds both the registry entry and the NixOS configuration for the Raspberry Pi 4). The directory a file lives in has no effect on behaviour.

> [!IMPORTANT]
> Nix flakes only see files tracked by `git`. After creating a new file, run `git add <file>` (no commit needed) or Nix will behave as if it does not exist.
