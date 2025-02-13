{ pkgs, config, ... }: {
  # Direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Yt-dlp  
  programs.yt-dlp = {
    enable = true;
    settings = {
      embed-thumbnail = true;
      embed-subs = true;
      sub-langs = "all";
      downloader = "aria2c";
      downloader-args = "aria2c:'-c -x8 -s8 -k1M'";
    };
  };

  # Nextcloud
  services.nextcloud-client = {
    enable = true;
    startInBackground = true;
  };

  # git signing
  home.file.".ssh/allowed_signers".text =
    "* ${builtins.readFile /home/${config.home.username}/.ssh/id_ed25519.pub}";

  # Git
  programs.git = {
    enable = true;
    lfs = { enable = true; };
    delta = {
      enable = true;
      options = {
        decorations = {
          commit-decoration-style = "bold yellow box ul";
          file-decoration-style = "none";
          file-style = "bold yellow ul";
        };
        features = "decorations";
        whitespace-error-style = "22 reverse";
      };
    };

    extraConfig = {
      # Sign all commits using ssh key
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519.pub";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
    };
    # signing = {
    #   signByDefault = true;
    # };

    userEmail = "vgfractal@gmail.com";
    userName = "Fractal-Tess";
  };

  # Kitty
  programs.kitty = {
    enable = true;
    font = {
      package = null;
      # Download font from here https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/CascadiaCode.zip
      name = "CaskaydiaCoveNerdFont";
      size = 12;
    };
    settings = {
      scrollback_lines = 10000;
      background_opacity = "0.75";
      # background_opacity = "1.0";
      background_blur = 96;
      update_check_interval = 0;
      enable_audio_bell = false;
      disable_ligatures = "never";
    };
    shellIntegration = { enableZshIntegration = true; };
  };

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Eza
  programs.eza = {
    enable = true;
    git = true;
    colors = "auto";
    enableZshIntegration = true;
    extraOptions = [ "--group-directories-first" "--header" ];
  };

  # Bat
  programs.bat = {
    enable = true;
    config = {
      map-syntax = [ "*.jenkinsfile:Groovy" "*.props:Java Properties" ];
      pager = "less -FR";
      theme = "TwoDark";
    };
    extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
    themes = {
      dracula = {
        src = pkgs.fetchFromGitHub {
          owner = "dracula";
          repo = "sublime"; # Bat uses sublime syntax for its themes
          rev = "26c57ec282abcaa76e57e055f38432bd827ac34e";
          sha256 = "019hfl4zbn4vm4154hh3bwk6hm7bdxbr1hdww83nabxwjn99ndhv";
        };
        file = "Dracula.tmTheme";
      };
    };
  };
}

