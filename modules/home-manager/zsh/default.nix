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
      ns = "nix search nixpkgs";
      cat = "bat";
      vpn = "openvpn ~/stuff/vpn/vpn.ovpn";
      update = "~/nixos/update.sh";
      wakevd = "sudo wakeonlan 00:D8:61:2E:DD:A9";
      ndc = "nix develop ~/nixos/shells/c";
      ndr = "nix develop ~/nixos/shells/rust";
      ndt = "nix develop ~/nixos/shells/tauri";
      ndn = "nix develop ~/nixos/shells/node";
      ndp = "nix develop ~/nixos/shells/python3";
      rt = "trash";
    };

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };
}
