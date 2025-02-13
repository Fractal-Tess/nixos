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

  # ZSH
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
      {
        name = "direnv";
        file = "plugins/direnv/direnv.plugin.zsh";
        src = fetchFromGitHub {
          owner = "ohmyzsh";
          repo = "ohmyzsh";
          rev = "1bae19973671dde75506c541ba576de4dae8cb29";
          sha256 = "sha256-fR4lxt1XRDZUBfQ2tAe7oLk2xpQTuOVH37o+njRvgxo=";
        };
      }
      {
        name = "sudo";
        src = fetchFromGitHub {
          owner = "ohmyzsh";
          repo = "ohmyzsh";
          rev = "f8bf8f0029a475831ebfba0799975ede20e08742";
          sha256 = "sha256-fR4lxt1XRDZUBfQ2tAe7oLk2xpQTuOVH37o+njRvgxo=";
        };
        file = "plugins/sudo/sudo.plugin.zsh";
      }
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
      grep = "batgrep";
      watch = "batwatch";

      # Base direnv initialization
      direnv-init =
        ''echo "use flake" >> .envrc && git add .envrc && direnv allow'';

      # Initialize git if needed and add flake files
      git-init-flake =
        "([ -d .git ] || git init) && git add flake.nix flake.lock";

      # Copy shell files and setup direnv
      ncs-setup =
        "cp ~/nixos/shells/$1/{flake.nix,flake.lock} ./ && git-init-flake && direnv-init";

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

