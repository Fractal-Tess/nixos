self: super: {
  terax = super.stdenv.mkDerivation {
    pname = "terax";
    version = "0.6.5";

    src = super.fetchurl {
      url = "https://github.com/crynta/terax-ai/releases/download/v0.6.5/Terax_0.6.5_amd64.AppImage";
      hash = "sha256-33JKSNHLxYhFLTTFEUGWhxsy9xfJkjND1BN7BAi9sMk=";
    };

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/opt $out/share/applications
      cp $src $out/opt/Terax.AppImage
      chmod +x $out/opt/Terax.AppImage

      cat > $out/bin/terax <<EOF
      #!${super.stdenv.shell}
      exec ${super.appimage-run}/bin/appimage-run $out/opt/Terax.AppImage "$@"
      EOF
      chmod +x $out/bin/terax

      cat > $out/share/applications/terax.desktop <<EOF
      [Desktop Entry]
      Name=Terax
      Comment=Lightweight AI-native terminal emulator (ADE)
      Exec=$out/bin/terax
      Icon=terminal
      Terminal=false
      Type=Application
      Categories=Development;Utility;TerminalEmulator;
      StartupWMClass=terax
      EOF

      runHook postInstall
    '';

    meta = with super.lib; {
      description = "Lightweight AI-native terminal emulator (ADE) built with Tauri 2 and React";
      homepage = "https://github.com/crynta/terax-ai";
      license = licenses.asl20;
      mainProgram = "terax";
      platforms = [ "x86_64-linux" ];
      maintainers = [ ];
    };
  };
}
