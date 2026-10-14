{ pkgs, profile }:
rec {
  distro = "jazzy";
  rospkgs = pkgs.rosPackages.${distro}; # ROS packages scoped by distro

  domainId = profile.domainId; # ROS_DOMAIN_ID

  # Environment variables used by the dev shell
  envVars = profile.env // {
    ROS_DOMAIN_ID = toString profile.domainId;
    GTK_PATH = "${pkgs.libcanberra-gtk3}/lib/gtk-3.0";
  };

  # Needed on both: core tooling, middleware, and message/interface packages
  sharedPackages =
    distro-pkgs:
    (with distro-pkgs; [
      python3Packages.argcomplete
      ros-core
      ros2run
      demo-nodes-cpp
    ])
    ++ profile.shared distro-pkgs;

  # Robot only: hardware integration and drivers
  robotPackages = distro-pkgs: sharedPackages distro-pkgs ++ profile.robot distro-pkgs;

  # Dev shell only: GUI and debugging tools
  devPackages = distro-pkgs: sharedPackages distro-pkgs ++ profile.dev distro-pkgs;

  # Using custom buildEnv from nix-ros-overlay to create ROS environment for dev shell
  devRosEnv = rospkgs.buildEnv { paths = devPackages rospkgs; };

  # Bash shell argument completion for ros2 and colcon commands
  argcompleteInit = ''
    if command -v register-python-argcomplete &> /dev/null; then
      eval "$(register-python-argcomplete ros2)"
      eval "$(register-python-argcomplete colcon)"
    fi
  '';
}
