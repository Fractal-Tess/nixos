{ config, pkgs, ... }: {

  programs.zsh = {
    # Enable zsh
    enable = true;
    # Enable zsh completion for all interactive shells
    enableCompletion = true;

    # Autosuggestions
    autosuggestion = {
      # Enable autosuggestions
      enable = true;
      # Fetch suggestions asynchronously
      async = true;
      # Use history and completion strategies
      strategy = [ "history" "completion" "match_prev_cmd" ];
    };
    # Syntax highlighting
    syntaxHighlighting.enable = true;

    initExtra = ''
      if [ -f "$HOME/.secrets.sh" ]; then
        source "$HOME/.secrets.sh"
      else
        echo "The file '.secrets.sh' is missing from ~/ . No secret environment variables will be loaded!"
      fi
    '';

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/.zsh_history";

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "direnv" "zsh-navigation-tools" ];
    };

    plugins = with pkgs; [
      {
        name = "powerlevel10k";
        src = zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = ./config;
        file = "p10k.config.zsh";
      }
    ];

    shellAliases = {
      pcuptime = "uptime | awk '{print $3}' | sed 's/,//'";
      cat = "bat";
      cc = "clipcopy";
      # Bat-extras aliases
      diff = "batdiff";
      man = "batman";

      update = "~/nixos/update.sh";

      ncs-setup =
        "function _ncs_setup() { cp ~/nixos/shells/$1/{flake.nix,flake.lock} ./ && _git_init_flake && _direnv_init; }; _ncs_setup";
      git-init-flake =
        "function _git_init_flake() { if [ ! -d .git ]; then git init; fi && git add flake.nix flake.lock; }; _git_init_flake";
      direnv-init =
        "function _direnv_init() { echo 'use flake' > .envrc && direnv allow; }; _direnv_init";

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

