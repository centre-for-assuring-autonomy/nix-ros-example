{ pkgs }:
rec {
  distro = "jazzy";
  rp = pkgs.rosPackages.${distro};

  # Needed on both: core tooling, middleware, and message/interface packages
  sharedPackages = p: with p; [
    python3Packages.argcomplete
    ros-core
    ros2run
    demo-nodes-cpp
  ];

  # Robot only: hardware integration and drivers
  robotPackages = p: with p; [
  ];

  # Dev shell only: GUI and debugging tools
  devPackages = p: with p; [
    rqt-gui
    rqt-gui-py
    rqt-graph
    rqt-topic
    rqt-console
  ];

  mkRosEnv = lists: rp.buildEnv {
    paths = builtins.concatMap (f: f rp) lists;
  };

  robotEnv = mkRosEnv [ sharedPackages robotPackages ];
  devRosEnv = mkRosEnv [ sharedPackages devPackages ];

  envVars = {
    RMW_IMPLEMENTATION = "rmw_fastrtps_cpp";
  };

  argcompleteInit = ''
    if command -v register-python-argcomplete &> /dev/null; then
      eval "$(register-python-argcomplete ros2)"
      eval "$(register-python-argcomplete colcon)"
    fi
  '';
}
