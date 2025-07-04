self: super: {
  # Overlay for Responsively App v1.16.0 using the official AppImage
  responsively-app = super.stdenv.mkDerivation rec {
    pname = "responsively-app";
    version = "1.16.0";

    src = super.fetchurl {
      url =
        "https://github.com/responsively-org/responsively-app-releases/releases/download/v1.16.0/ResponsivelyApp-1.16.0.AppImage";
      sha256 = "sha256-r0wznN+7zZXKNFNFUV4hm2e4gd84M6hVcun4OfNEeSw=";
    };

    dontUnpack = true;
    buildInputs = [ super.appimage-run ];

    installPhase = ''
      # Store the AppImage in $out/opt
      mkdir -p $out/opt
      cp $src $out/opt/ResponsivelyApp.AppImage
      chmod +x $out/opt/ResponsivelyApp.AppImage

      # Create a wrapper script in $out/bin that launches the AppImage with appimage-run
      mkdir -p $out/bin
      cat > $out/bin/responsively-app <<EOF
      #!${super.stdenv.shell}
      exec ${super.appimage-run}/bin/appimage-run $out/opt/ResponsivelyApp.AppImage "$@"
      EOF
      chmod +x $out/bin/responsively-app
    '';

    meta = with super.lib; {
      description =
        "A modified browser for fast & precise responsive web development.";
      homepage = "https://responsively.app/";
      license = licenses.mit;
      platforms = platforms.linux;
      maintainers = with maintainers; [ ];
    };
  };
}
