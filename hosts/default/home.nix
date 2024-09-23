{ pkgs, ... }: {
  imports =
    [
      ../../modules/home-manager/bat/default.nix
      ../../modules/home-manager/btop/default.nix
      ../../modules/home-manager/dunst/default.nix
      ../../modules/home-manager/eza/default.nix
      ../../modules/home-manager/flameshot/default.nix
      # ../../modules/home-manager/gh/default.nix
      ../../modules/home-manager/git/default.nix
      ../../modules/home-manager/kitty/default.nix
      ../../modules/home-manager/lf/default.nix
      ../../modules/home-manager/mpv/default.nix
      ../../modules/home-manager/neovim/default.nix
      ../../modules/home-manager/nextcloud/default.nix
      ../../modules/home-manager/obs-studio/default.nix
      ../../modules/home-manager/picom/default.nix
      ../../modules/home-manager/ripgrep/default.nix
      ../../modules/home-manager/rofi/default.nix
      ../../modules/home-manager/warp-terminal/default.nix
      ../../modules/home-manager/yt-dlp/default.nix
      ../../modules/home-manager/zathura/default.nix
      ../../modules/home-manager/zoxide/default.nix
      ../../modules/home-manager/zsh/default.nix
    ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "fractal-tess";
  home.homeDirectory = "/home/fractal-tess";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    # Docker
    docker-compose
    buildkit

    # Development
    vscode # Code editor
    man-pages # Linux development manual pages

    # General gui
    polybarFull # Full polybar with all modules
    nomacs # Image viewer
    obsidian # Note taking
    logseq # Note taking
    gitkraken # Git GUI
    vlc # Media player
    pcmanfm # File manager
    audacity # Audio editor
    avidemux # Video editor

    font-manager # Font manager
    # font-viewer # Font previewer
    pavucontrol # Pulseaudio volume control
    nitrogen # Wallpaper setter
    pulseaudio # Audio channel manager
    bitwarden # Password manager
    gparted # Partition manager
    kicad # PCB design
    gimp # Image editor
    blender # 3D modeling
    inkscape # Vector graphics
    steam # Gaming platform
    libreoffice # Office suite
    discord # Chat platform
    # viber # Chat platform  -- uses openssl-1.1.1w which is insecure
    slack # Chat platform
    thunderbird # Email client
    postman # API testing
    insomnia # API testing
    netbird-ui # UI for netbird
    # netbird-dashboard # Dashboard for netbird
    lazygit # Git GUI


    # Utils 
    lm_sensors # System sensors
    gpick # Color picker
    geekbench # System benchmark
    jq # JSON parser
    carbon-now-cli # Code to image
    hyperfine # Command benchmark
    skim # Fuzzy finder
    sd # Sed alternative
    bottom # System monitor
    procs # ps replacement
    fd # Find replacement
    tokei # Code stats
    dust # Disk usage
    unzip # Unzip files
    trash-cli # Trash files
    openssl_3_3 # SSL
    xclip # Stdout to  clipboard 
    gh # Github CLI
    light # Screen brightness
    # brightnessctl # Screen brightness
    ffmpeg-full # Video converter

    # Browsers
    microsoft-edge # Edge browser
    google-chrome # Chrome browser
    firefox # Firefox browser

    # Networking
    filezilla # FTP client
    burpsuite # Web pentesting
    ngrok # Tunneling
    nmap # Network scanner
    oha # HTTP bentchmarker
    openvpn # VPN
    wakeonlan # Wake on lan util
    hping # Network ping(ICMP) tool

    # Flex
    cava # Audio visualizer
    lolcat # Colorful gradient stdin to stdout
    neofetch # System info
    # screenfetch # System info


  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/fractal-tess/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
