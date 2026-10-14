{ ... }:
{
  flake.modules.nixos.system = {

    # Configure bash shell options
    programs.bash = {
      completion.enable = true;
      # Append commands to history immediately, not only at shell exit
      # Also share command history with other terminal sessions
      interactiveShellInit = ''
        export HISTFILE="$HOME/.local/state/bash/history"
        export HISTSIZE=10000
        export HISTFILESIZE=100000
        shopt -s histappend
        PROMPT_COMMAND="history -a; history -n''${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
      '';
    };

    # Persist bash history
    environment.persistence."/persist".users.robot.directories = [
      ".local/state/bash"
    ];
  };
}
