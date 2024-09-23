{ config, pkgs, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    enableVteIntegration = true;
    syntaxHighlighting.enable = true;

    # initExtra = ''
    #   [[ ! -f ${./p10k.zsh} ]] || source ${./p10k.zsh}
    # '';
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = ./p10k-config;
        file = "p10k.zsh";
      }
    ];

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "zsh-navigation-tools"
      ];
    };

    shellAliases = {
      pcuptime = "uptime | awk '{print $3}' | sed 's/,//'";
      cat = "bat";

      direnv-init = "echo \"use flake\" >> .envrc && direnv allow";
      ncs-nodejs = "cp ~/nixos/shells/node/* ./";

      ndmaui = "nix develop ~/nixos/shells/maui";
      ndcsharp = "nix develop ~/nixos/shells/csharp";
      ndc = "nix develop ~/nixos/shells/c";
      ndgo = "nix develop ~/nixos/shells/go";
      ndrust = "nix develop ~/nixos/shells/rust";
      ndtauri = "nix develop ~/nixos/shells/tauri";
      ndnode = "nix develop ~/nixos/shells/node --command zsh";
      ndpython = "nix develop ~/nixos/shells/python3";
      ndnet = "nix develop ~/nixos/shells/networking";
      ndphp = "nix develop ~/nixos/shells/php";
      ndreact-native = "nix develop ~/nixos/shells/react-native";
    };

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };
}
