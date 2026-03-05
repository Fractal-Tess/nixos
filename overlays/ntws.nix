self: super: {
  ntws = super.stdenv.mkDerivation rec {
    pname = "ntws";
    version = "latest-standalone";

    src = super.fetchurl {
      url = "https://download2.interactivebrokers.com/installers/ntws/latest-standalone/ntws-latest-standalone-linux-x64.sh";
      sha256 = "sha256-NoCUH0lJwtUzat6Xm/1aZerYCDSCORHA+01nuKXfsjM=";
    };

    dontUnpack = true;

    runtimeLibs = with super; [
      alsa-lib
      gtk3
      krb5
      libGL
      libdrm
      libglvnd
      libx11
      libxcb
      libxcursor
      libxext
      libxi
      libxinerama
      libxkbcommon
      libxrandr
      libxrender
      libxtst
      libxxf86vm
      nspr
      nss
      stdenv.cc.cc.lib
      xcbutil
      xcbutilimage
      xcbutilkeysyms
      xcbutilrenderutil
      xcbutilwm
      zlib
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/libexec" "$out/bin" "$out/share/applications"

      cp "$src" "$out/libexec/ntws-installer.sh"
      chmod +x "$out/libexec/ntws-installer.sh"

      cat > "$out/bin/ntws" <<EOF
      #!${super.stdenv.shell}
      set -e

      export LD_LIBRARY_PATH="${super.lib.makeLibraryPath runtimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      install_root="''${XDG_DATA_HOME:-$HOME/.local/share}/ntws"

      if [ ! -x "\$install_root/ntws" ]; then
        mkdir -p "\$install_root"
        "$out/libexec/ntws-installer.sh" -q -overwrite -dir "\$install_root"
      fi

      exec "\$install_root/ntws" "\$@"
      EOF
      chmod +x "$out/bin/ntws"

      cat > "$out/share/applications/ntws.desktop" <<EOF
      [Desktop Entry]
      Name=IBKR Desktop (NTWS)
      Comment=Interactive Brokers Desktop trading platform
      Exec=$out/bin/ntws
      Terminal=false
      Type=Application
      Categories=Office;Finance;
      StartupWMClass=IBKR Desktop
      EOF

      runHook postInstall
    '';

    meta = with super.lib; {
      description = "Interactive Brokers Desktop launcher (installs NTWS into user data dir on first run)";
      homepage = "https://www.interactivebrokers.com/";
      license = licenses.unfree;
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
      platforms = platforms.linux;
      maintainers = [ ];
    };
  };
}
