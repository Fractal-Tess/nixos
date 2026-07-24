self: super: {
  # Overlay for Responsively App v1.16.0 using the official AppImage
  responsively-app = super.stdenv.mkDerivation {
    pname = "responsively-app";
    version = "1.16.0";

    src = super.fetchurl {
      url = "https://github.com/responsively-org/responsively-app-releases/releases/download/v1.16.0/ResponsivelyApp-1.16.0.AppImage";
      sha256 = "sha256-r0wznN+7zZXKNFNFUV4hm2e4gd84M6hVcun4OfNEeSw=";
    };

    dontUnpack = true;
    buildInputs = [ super.appimage-run ];

    installPhase = ''
      runHook preInstall

      # Store the AppImage in $out/opt
      mkdir -p $out/bin $out/opt $out/share/applications
      cp $src $out/opt/ResponsivelyApp.AppImage
      chmod +x $out/opt/ResponsivelyApp.AppImage

      # Create a wrapper script in $out/bin that launches the AppImage with appimage-run
      # Always passes --ozone-platform=x11 for compatibility
      cat > $out/bin/responsively-app <<EOF
      #!${super.stdenv.shell}
      exec ${super.appimage-run}/bin/appimage-run $out/opt/ResponsivelyApp.AppImage --ozone-platform=x11 "$@"
      EOF
      chmod +x $out/bin/responsively-app

      cat > $out/share/applications/responsively-app.desktop <<EOF
      [Desktop Entry]
      Name=Responsively App
      Comment=Develop responsive web applications from one place
      Exec=$out/bin/responsively-app
      Icon=applications-development
      Terminal=false
      Type=Application
      Categories=Development;WebDevelopment;
      Keywords=responsive;browser;web;development;
      StartupWMClass=ResponsivelyApp
      EOF

      runHook postInstall
    '';

    meta = with super.lib; {
      description = "A modified browser for fast & precise responsive web development.";
      homepage = "https://responsively.app/";
      license = licenses.mit;
      mainProgram = "responsively-app";
      platforms = platforms.linux;
      maintainers = [ ];
    };
  };
}
