self: super: {
  # Overlay for Viber official AppImage, wrapped with appimage-run for NixOS compatibility
  viber-appimage = super.stdenv.mkDerivation {
    pname = "viber-appimage";
    version = "latest"; # Update if you want to pin a version

    # Download the official AppImage
    src = super.fetchurl {
      url = "https://download.cdn.viber.com/desktop/Linux/viber.AppImage";
      sha256 =
        "sha256-jwsePK1l/WI+stDNpAD1t2Obr1BwpNDP0nzkIDfGGoA="; # Verified hash
    };

    # Add appimage-run and makeWrapper to buildInputs
    buildInputs = [ super.appimage-run super.makeWrapper ];
    dontUnpack = true;

    installPhase = ''
      # Create the output bin directory
      mkdir -p $out/bin
      # Copy the AppImage to the output directory
      cp $src $out/viber.AppImage
      # Create a wrapper that runs the AppImage with appimage-run
      makeWrapper ${super.appimage-run}/bin/appimage-run $out/bin/viber \
        --add-flags "$out/viber.AppImage"
    '';

    meta = {
      description = "Viber official AppImage (wrapped for NixOS)";
      homepage = "https://www.viber.com/";
      license = super.lib.licenses.unfree;
      maintainers = with super.lib.maintainers; [ ];
      platforms = [ "x86_64-linux" ];
    };
  };
}
