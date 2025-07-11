self: super: {
  # Overlay for Viber official AppImage
  viber-appimage = super.stdenv.mkDerivation {
    pname = "viber-appimage";
    version = "latest"; # Update if you want to pin a version

    # Download the official AppImage
    src = super.fetchurl {
      url = "https://download.cdn.viber.com/desktop/Linux/viber.AppImage";
      sha256 =
        "sha256-S+PpVbMq30p6PECUfdp2FESbqFk9lTbaadNFUDs7TkE="; # TODO: Replace with real hash after first build
    };

    dontUnpack = true;

    installPhase = ''
      # Create the output bin directory
      mkdir -p $out/bin
      # Copy the AppImage to the output bin directory
      cp $src $out/bin/viber
      # Make the AppImage executable
      chmod +x $out/bin/viber
    '';

    meta = {
      description = "Viber official AppImage";
      homepage = "https://www.viber.com/";
      license = super.lib.licenses.unfree;
      maintainers = with super.lib.maintainers; [ ];
      platforms = [ "x86_64-linux" ];
    };
  };
}
