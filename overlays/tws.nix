final: prev: {
  tws = prev.buildFHSEnv {
    name = "tws";
    runScript = prev.writeScript "tws-run" ''
      #!${prev.stdenv.shell}
      TWS_HOME="''${TWS_HOME:-$HOME/Jts}"

      # Install TWS if not already installed
      if [ ! -f "$TWS_HOME/tws" ]; then
        echo "TWS not found at $TWS_HOME. Running installer..."
        installer="$HOME/Downloads/tws-latest-linux-x64.sh"
        if [ ! -f "$installer" ]; then
          echo "Downloading TWS installer..."
          ${prev.curl}/bin/curl -Lo "$installer" \
            "https://download2.interactivebrokers.com/installers/tws/latest/tws-latest-linux-x64.sh"
          chmod +x "$installer"
        fi
        sh "$installer" -q -dir "$TWS_HOME"
      fi

      exec "$TWS_HOME/tws" "$@"
    '';

    targetPkgs = pkgs: with pkgs; [
      # Java / JVM
      zulu17

      # X11 / GUI
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      xorg.libXtst
      xorg.libXi
      xorg.libXrandr
      xorg.libXcursor
      xorg.libXfixes
      xorg.libXinerama
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXScrnSaver
      xorg.libxcb

      # GTK / Desktop integration
      gtk3
      glib
      gdk-pixbuf
      pango
      cairo
      atk
      dbus
      at-spi2-atk

      # System libs
      glibc
      zlib
      freetype
      fontconfig
      alsa-lib
      libGL
      libGLU
      mesa
      libpulseaudio
      nss
      nspr
      cups
      expat
      udev
      libdrm

      # Networking
      curl
      openssl
    ];

    profile = ''
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';

    meta = with prev.lib; {
      description = "Interactive Brokers Trader Workstation";
      homepage = "https://www.interactivebrokers.com";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
    };
  };
}
