self: super: {
  # Overlay for Responsively App v1.16.0 using the official AppImage
  responsively-app = super.stdenv.mkDerivation rec {
    pname = "responsively-app";
    version = "1.16.0";

    src = super.fetchurl {
      url =
        "https://github.com/responsively-org/responsively-app-releases/releases/download/v1.16.0/ResponsivelyApp-1.16.0.AppImage";
      sha256 =
        "sha256-r0wznN+7zZXKNFNFUV4hm2e4gd84M6hVcun4OfNEeSw="; # TODO: Replace with real hash
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/ResponsivelyApp
      chmod +x $out/bin/ResponsivelyApp
      # Optionally, create a symlink for easier invocation
      ln -s $out/bin/ResponsivelyApp $out/bin/responsively-app
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
