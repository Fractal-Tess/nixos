{ pkgs, username, ... }: {
  services = {
    syncthing = {
      enable = true;
      user = "fractal-tess";
      dataDir = "/home/${username}/syncthing"; # Default folder for new synced folders
      configDir = "/home/fractal-tess/.config/syncthing"; # Folder for Syncthing's settings and keys
    };


    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
      };
    };
  };

  programs = {
    dconf = {
      enable = true;
    };
    # Yazi
    yazi = {
      enable = true;
    };

    # Direnv
    direnv = {
      enable = true;
      enableZshIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };
  };


  # Mobile dev
  programs.adb.enable = true;
  # services.udev.packages = [
  #   pkgs.android-udev-rules
  # ];

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Docker
  virtualisation.docker.enable = true;

  # Zram 
  zramSwap.enable = true;

  # # Needed for zsh
  environment.pathsToLink = [ "/share/zsh" ];
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;


  # Default applications
  xdg.mime.defaultApplications = {
    # Media files for VLC
    "audio/mpeg" = "vlc.desktop";
    "video/mp4" = "vlc.desktop";
    "video/mpeg" = "vlc.desktop";
    "video/x-matroska" = "vlc.desktop";
    "video/x-msvideo" = "vlc.desktop";

    # Image files for Nomacs
    "image/jpeg" = "org.nomacs.ImageLounge.desktop";
    "image/png" = "org.nomacs.ImageLounge.desktop";
    "image/gif" = "org.nomacs.ImageLounge.desktop";
    "image/bmp" = "org.nomacs.ImageLounge.desktop";

    # SVG files for Inkscape
    "image/svg+xml" = "org.inkscape.Inkscape.desktop";
  };



  # keyboard
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 224 ]; events = [ "key" ]; command = "/etc/profiles/per-user/fractal-tess/bin/light -U 10"; }
      { keys = [ 225 ]; events = [ "key" ]; command = "/etc/profiles/per-user/fractal-tess/bin/light -A 10"; }
    ];
  };
}
