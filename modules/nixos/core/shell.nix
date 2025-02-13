{ config, pkgs, ... }: {

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    autosuggestion.strategy = [ "history" "completion" ];
    enableVteIntegration = true;
    syntaxHighlighting.enable = true;

    initExtra = ''
      if [ -f "$HOME/.secrets.sh" ]; then
        source "$HOME/.secrets.sh"
      else
        echo "The file '.secrets.sh' is missing from ~/ . No secret environment variables will be loaded!"
      fi
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "direnv" ];
      theme = "powerlevel10k";
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
      # {
      #   name = "direnv";
      #   file = "plugins/direnv/direnv.plugin.zsh";
      #   src = fetchFromGitHub {
      #     owner = "ohmyzsh";
      #     repo = "ohmyzsh";
      #     rev = "1bae19973671dde75506c541ba576de4dae8cb29";
      #     sha256 = "sha256-fR4lxt1XRDZUBfQ2tAe7oLk2xpQTuOVH37o+njRvgxo=";
      #   };
      # }
      # {
      #   name = "sudo";
      #   src = fetchFromGitHub {
      #     owner = "ohmyzsh";
      #     repo = "ohmyzsh";
      #     rev = "f8bf8f0029a475831ebfba0799975ede20e08742";
      #     sha256 = "sha256-fR4lxt1XRDZUBfQ2tAe7oLk2xpQTuOVH37o+njRvgxo=";
      #   };
      #   file = "plugins/sudo/sudo.plugin.zsh";
      # }
      # {
      #   name = "zsh-navigation-tools";
      #   src = fetchFromGitHub {
      #     owner = "ohmyzsh";
      #     repo = "ohmyzsh";
      #     rev = "d78275fdbb876cee9c55f5c2731b8c1fac7be6d2";
      #     sha256 = "sha256-fR4lxt1XRDZUBfQ2tAe7oLk2xpQTuOVH37o+njRvgxo=";
      #   };
      #   file = "plugins/zsh-navigation-tools/zsh-navigation-tools.plugin.zsh";
      # }
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

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };
}

