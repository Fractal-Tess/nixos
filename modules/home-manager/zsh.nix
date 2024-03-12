{ config, pkgs, ... }: {
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
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
      # update = "~/nixos/update.sh";
      ls = "eza";
      ll = "eza -l";
      cat = "bat";
      update = "~/nixos/update.sh";
      wakevd = "wakeonlan 00:D8:61:2E:DD:A9";
    };

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };
}
