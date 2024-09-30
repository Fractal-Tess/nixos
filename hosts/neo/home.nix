{ pkgs, username, osConfig, lib, ... }: {
  imports =
    [
      ../../modules/home-manager/bat/default.nix
      ../../modules/home-manager/btop/default.nix
      ../../modules/home-manager/eza/default.nix
      ../../modules/home-manager/gh/default.nix
      ../../modules/home-manager/git/default.nix
      ../../modules/home-manager/kitty/default.nix
      ../../modules/home-manager/mpv/default.nix
      ../../modules/home-manager/neovim/default.nix
      ../../modules/home-manager/nextcloud/default.nix
      ../../modules/home-manager/obs-studio/default.nix
      ../../modules/home-manager/ripgrep/default.nix
      ../../modules/home-manager/warp-terminal/default.nix
      ../../modules/home-manager/yt-dlp/default.nix
      ../../modules/home-manager/zathura/default.nix
      ../../modules/home-manager/zoxide/default.nix
      ../../modules/home-manager/zsh/default.nix
    ];

  # Home Manager 
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # File sync
  services.syncthing.enable = true;

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

  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };


  home.stateVersion = "24.05";


  home.packages = with pkgs; [
    # Docker
    docker-compose
    buildkit

    # Wallpaper manager
    swww
    waypaper

    # Notifications 
    swaynotificationcenter

    # Rofi 
    wofi
    xfce.thunar

    # Pactl
    pulseaudio

    # Development
    vscode # Code editor
    flyctl # Fly.io CLI
    gh # Github CLI
    lazygit # Git GUI
    man-pages # Linux development manual pages
    gitkraken # Git GUI
    fzf # Fuzzy finder
    dbgate # DB client
    dbeaver-bin # DB client
    hyprpicker # Color picker

    # Networking
    netbird-ui # UI for netbird
    postman # API testing
    insomnia # API testing
    filezilla # FTP client
    burpsuite # Web pentesting
    ngrok # Tunneling
    nmap # Network scanner
    oha # HTTP bentchmarker
    openvpn # VPN
    wakeonlan # Wake on lan util
    hping # Network ping  util

    # General 
    kooha # Screen recorder
    nomacs # Image viewer
    obsidian # Note taking
    logseq # Note taking
    vlc # Media player
    pcmanfm # File manager
    lxmenu-data
    shared-mime-info

    # Audio
    playerctl
    pamixer
    pavucontrol # Pulseaudio volume control

    # Media editing
    #avidemux # Video editor
    audacity # Audio editor
    gimp # Image editor
    blender # 3D modeling
    inkscape # Vector graphics
    ffmpeg-full # Video converter

    # Fonts & Themes
    nordic # Theme
    font-manager # Font manager

    cliphist # Clipboard history


    # Communication
    bitwarden # Password manager
    gparted # Partition manager
    kicad # PCB design
    libreoffice # Office suite
    discord # Chat platform
    viber # Chat platform 
    slack # Chat platform
    thunderbird # Email client


    # Games 
    steam # Gaming platform
    polymc # Minecraft launcher


    # Utils 
    ventoy-full # Bootable USB creator
    woeusb-ng # Windows USB creator
    stress # Cpu stress
    lm_sensors # System sensors
    gpick # Color picker
    geekbench # System benchmark
    jq # JSON parser
    carbon-now-cli # Code to image
    hyperfine # Command benchmark -- 
    skim # Fuzzy finder
    sd # Sed alternative
    bottom # System monitor
    procs # ps replacement
    fd # Find replacement
    tokei # Code stats --
    dust # Disk usage
    unzip # Unzip files
    p7zip # 7zip
    trash-cli # Trash files
    mate.engrampa # Archive manager
    nh # Nix cli 

    wl-clipboard # Clipboard for neovim
    grim # Wayland screenshotter
    slurp # Screen coordinates picker

    # Browsers
    microsoft-edge # Edge browser
    google-chrome # Chrome browser
    firefox # Firefox browser # Clipboard for neovim


    # Flex
    cava # Audio visualizer
    lolcat # Colorful gradient stdin to stdout
    neofetch # System info
    nitch # System info
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
  xdg.configFile.hypr = lib.mkIf osConfig.modules.display.hyprland.enable {
    source = ../../modules/nixos/display/hyprland/config;
    recursive = true;
  };
  xdg.configFile.waybar = lib.mkIf osConfig.modules.display.waybar.enable {
    source = ../../modules/nixos/display/waybar/config;
    recursive = true;
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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
