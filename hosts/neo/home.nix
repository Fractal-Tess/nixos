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
      # ../../modules/home-manager/nextcloud/default.nix
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
  home.username = "fractal-tess";
  home.homeDirectory = "/home/fractal-tess";



  # Eenvironment variables
  home.sessionVariables = {
    GTK_THEME = "Nordic";
    XCURSOR_THEME = "Nordzy-cursors";
    XCURSOR_SIZE = "24";


    # Silence direnv env loading ouput
    DIRENV_LOG_FORMAT = "";

    # If cursor becomes invisible
    # WLR_NO_HARDWARE_CURSORS = "1";

    # Hint to electron apps to use wayland
    NIXOS_OZONE_WL = "1";

    # Editor
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
    EDITOR = "nvim";

    # Firefox
    MOZ_USE_WAYLAND = 1;
    MOZ_USE_XINPUT2 = 1;
  };

  # Theming
  gtk = {
    enable = true;
    theme = {
      name = "Nordic-darker";
      package = pkgs.nordic;
    };
    iconTheme = {
      name = "Nordzy-dark";
      package = pkgs.nordzy-icon-theme;
    };
    cursorTheme = {
      name = "Nordzy-cursors";
      package = pkgs.nordzy-cursor-theme;
      size = 32;
    };
  };

  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    # Docker
    docker-compose
    buildkit

    # Torrenting clients
    qbittorrent

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
    viber # Chat platform  
    slack # Chat platform
    thunderbird # Email client
    postman # API testing
    insomnia # API testing
    netbird-ui # UI for netbird
    lazygit # Git GUI
    nh # Nix cli 


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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
