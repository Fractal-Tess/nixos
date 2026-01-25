self: super: {
  # Overlay for Handy v0.7.0 - A free, open source speech-to-text application
  handy = super.stdenv.mkDerivation rec {
    pname = "handy";
    version = "0.7.0";

    src = super.fetchurl {
      url =
        "https://github.com/cjpais/Handy/releases/download/v0.7.0/Handy_0.7.0_amd64.AppImage";
      sha256 = "sha256-tTswFYLCPGtMbHAb2bQMsklRiRCVXLrtu4pQC8IHdqQ=";
    };

    dontUnpack = true;
    nativeBuildInputs = [ super.makeWrapper ];
    buildInputs = [ super.appimage-run ];

    installPhase = ''
      # Store the AppImage in $out/opt
      mkdir -p $out/opt
      cp $src $out/opt/Handy.AppImage
      chmod +x $out/opt/Handy.AppImage

      # Create a wrapper script in $out/bin that launches the AppImage with appimage-run
      mkdir -p $out/bin
      cat > $out/bin/handy <<EOF
      #!${super.stdenv.shell}
      exec ${super.appimage-run}/bin/appimage-run $out/opt/Handy.AppImage "$@"
      EOF
      chmod +x $out/bin/handy

      # Create desktop entry for application launcher
      mkdir -p $out/share/applications
      cat > $out/share/applications/handy.desktop <<EOF
      [Desktop Entry]
      Name=Handy
      Comment=Offline speech-to-text application
      Exec=$out/bin/handy
      Icon=audio-input-microphone
      Terminal=false
      Type=Application
      Categories=AudioVideo;Audio;Recorder;Utility;
      Keywords=speech;transcription;stt;voice;dictation;
      StartupWMClass=Handy
      EOF
    '';

    meta = with super.lib; {
      description =
        "A free, open source, and extensible speech-to-text application that works completely offline.";
      homepage = "https://github.com/cjpais/Handy";
      license = licenses.mit;
      platforms = platforms.linux;
      maintainers = with maintainers; [ ];
    };
  };
}
