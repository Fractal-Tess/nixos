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

      install_root="''${XDG_DATA_HOME:-$HOME/.local/share}/ntws"
      install_log="''${XDG_CACHE_HOME:-$HOME/.cache}/ntws/install.log"
      marker_file="\$install_root/.installed-version"
      lock_file="\$install_root/.install.lock"
      expected_version="${version}"

      mkdir -p "\$install_root"

      while ! (set -o noclobber; : > "\$lock_file") 2>/dev/null; do
        sleep 1
      done
      trap 'rm -f "\$lock_file"' EXIT

      needs_install=0
      if [ ! -x "\$install_root/ntws" ]; then
        needs_install=1
      elif [ ! -f "\$marker_file" ] || [ "\$(cat "\$marker_file")" != "\$expected_version" ]; then
        needs_install=1
      fi

      if [ "\$needs_install" -eq 1 ]; then
        mkdir -p "\$(dirname "\$install_log")"
        if ! "$out/libexec/ntws-installer.sh" -q -overwrite -dir "\$install_root" >"\$install_log" 2>&1; then
          echo "NTWS installation failed. See log: \$install_log" >&2
          exit 1
        fi
        if [ ! -x "\$install_root/ntws" ]; then
          echo "NTWS installation completed but launcher was not found at \$install_root/ntws" >&2
          exit 1
        fi
        printf '%s\n' "\$expected_version" > "\$marker_file"
      fi

      exec env LD_LIBRARY_PATH="${super.lib.makeLibraryPath runtimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "\$install_root/ntws" "\$@"
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
