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
    };
    shellGlobalAlias =
      {
        update = ''
          set -e
          pushd ~/nixos
          nixpkgs-fmt . &>/dev/null
          # git diff -U0 *.nix
          git diff -U0 ':!*.log'
          echo "Rebuilding NixOS..."
          sudo nixos-rebuild switch &>nixos-switch.log || (cat nixos-switch.log | rg error && false)
          gen=$(nixos-rebuild list-generations | head -n 2 | tail -1 | awk '{print $1}')
          git add .
          git commit -m "$gen"
          # try pushing to origin but don't fail if git exists with 1
          # print a message if it fails
          echo "Trying to push commit to origin..."
          git push origin main || echo "Failed to push to origin"
          popd
        '';
      };

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };
}
