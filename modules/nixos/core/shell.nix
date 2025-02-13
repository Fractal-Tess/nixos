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
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      if [ -f "$HOME/.secrets.sh" ]; then
        source "$HOME/.secrets.sh"
      else
        echo "The file '.secrets.sh' is missing from ~/ . No secret environment variables will be loaded!"
      fi

      # Direnv & Shell helpers 
      function _ncs_setup() {
        cp ~/nixos/shells/$1/{flake.nix,flake.lock} ./
        _git_init_flake
        _direnv_init
      }

      function _git_init_flake() {
        if [ ! -d .git ]; then
          git init
        fi
        git add flake.nix flake.lock
      }

      function _direnv_init() {
        echo 'use flake' > .envrc
        direnv allow
      }
    '';
    # promptInit =
    #   "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

    histSize = 10000;
    histFile = "$HOME/.zsh_history";

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "direnv" "zsh-navigation-tools" "zoxide" ];
    };

    # plugins = with pkgs; [
    #   # {
    #   #   name = "powerlevel10k";
    #   #   src = zsh-powerlevel10k;
    #   #   file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    #   # }
    #   {
    #     name = "powerlevel10k-config";
    #     src = ./config;
    #     file = "p10k.config.zsh";
    #   }
    # ];

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
      ncs-c = "ncs-setup c";
      ncs-csharp = "ncs-setup csharp";
      ncs-go = "ncs-setup go";
      ncs-java = "ncs-setup java";
      ncs-maui = "ncs-setup maui";
      ncs-php = "ncs-setup php";
      ncs-nodejs = "ncs-setup node";
      ncs-python = "ncs-setup python3";
      ncs-react-native = "ncs-setup react-native";
      ncs-rust = "ncs-setup rust";
      ncs-tauri = "ncs-setup tauri";
      ncs-unity = "ncs-setup unity";

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

