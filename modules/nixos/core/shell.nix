{ pkgs, ... }:

{
  # Enable ZSH  as the default shell (config is done in home-manager)
  users.defaultUserShell = pkgs.zsh;

  # ZSH
  programs.zsh = {

    # Enable zsh
    enable = true;
    # Enable zsh completion for all interactive shells
    enableCompletion = true;

    # Autosuggestions
    autosuggestions = {
      # Enable autosuggestions
      enable = true;
      # Fetch suggestions asynchronously
      async = true;
      # Use history and completion strategies
      strategy = [ "history" "completion" "match_prev_cmd" ];
    };
    # Syntax highlighting
    syntaxHighlighting.enable = true;

    promptInit = ''
      # Powerlevel10k
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      # Powerlevel10k config
      source ~/nixos/modules/nixos/core/config/.p10k.zsh
      # Direnv
      source ~/nixos/modules/nixos/core/config/.direnv.zsh

      # Secrets
      if [ -f "$HOME/.secrets.sh" ]; then
        source "$HOME/.secrets.sh"
      else
        echo "The file '.secrets.sh' is missing from ~/ . No secret environment variables will be loaded!"
      fi

    '';

    histSize = 10000;
    histFile = "$HOME/.zsh_history";

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "direnv" "zsh-navigation-tools" "zoxide" ];
    };

    shellAliases = {
      pcuptime = "uptime | awk '{print $3}' | sed 's/,//'";
      cat = "bat";
      cc = "clipcopy";
      # Bat-extras aliases
      diff = "batdiff";
      man = "batman";

      ll = "eza -l";
      ls = "eza";

      update = "~/nixos/update.sh";

      # Individual language shell setup commands
      ncs-c = "_ncs_setup c";
      ncs-csharp = "_ncs_setup csharp";
      ncs-go = "_ncs_setup go";
      ncs-java = "_ncs_setup java";
      ncs-maui = "_ncs_setup maui";
      ncs-php = "_ncs_setup php";
      ncs-nodejs = "_ncs_setup node";
      ncs-python = "_ncs_setup python3";
      ncs-react-native = "_ncs_setup react-native";
      ncs-rust = "_ncs_setup rust";
      ncs-tauri = "_ncs_setup tauri";
      ncs-unity = "_ncs_setup unity";

      # Alternative commands that just execute nix develop
      nas-c = "nix develop ~/nixos/shells/c";
      nas-csharp = "nix develop ~/nixos/shells/csharp";
      nas-go = "nix develop ~/nixos/shells/go";
      nas-java = "nix develop ~/nixos/shells/java";
      nas-maui = "nix develop ~/nixos/shells/maui";
      nas-php = "nix develop ~/nixos/shells/php";
      nas-nodejs = "nix develop ~/nixos/shells/node";
      nas-python = "nix develop ~/nixos/shells/python3";
      nas-react-native = "nix develop ~/nixos/shells/react-native";
      nas-rust = "nix develop ~/nixos/shells/rust";
      nas-tauri = "nix develop ~/nixos/shells/tauri";
      nas-unity = "nix develop ~/nixos/shells/unity";
    };

  };
}

