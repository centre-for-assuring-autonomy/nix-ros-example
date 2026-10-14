{ lib, ... }:
let
  # Used to create a tailored configuration for a specific robot platform
  profileModule = {
    options = {
      domainId = lib.mkOption {
        type = lib.types.int;
        default = 0;
      };
      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
      };
      shared = lib.mkOption {
        type = lib.types.functionTo (lib.types.listOf lib.types.raw);
        default = _: [ ];
      };
      robot = lib.mkOption {
        type = lib.types.functionTo (lib.types.listOf lib.types.raw);
        default = _: [ ];
      };
      dev = lib.mkOption {
        type = lib.types.functionTo (lib.types.listOf lib.types.raw);
        default = _: [ ];
      };
      overlays = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
      };
    };

    # Base profile configuration that other profiles build upon
    config = {
      env.RMW_IMPLEMENTATION = "rmw_fastrtps_cpp";
      dev =
        distro-pkgs: with distro-pkgs; [
          rqt-gui
          rqt-gui-py
          rqt-graph
          rqt-topic
          rqt-console
          rviz2
        ];
    };
  };
in
{
  # Definition of `ros.profiles` attribute set
  options.ros.profiles = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule profileModule);
    default = { };
  };

  # Instantiate the `base` profile with the default configuration
  config.ros.profiles.base = { };
}
