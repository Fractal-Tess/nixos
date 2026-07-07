final: prev: {
  # Build libxml2 2.12.7 which has the valuePush symbol needed by Viber's Qt6 WebEngine
  # (libxml2 ≥2.13.0 removed valuePush, causing symbol lookup errors)
  libxml2-viber-compat = final.stdenv.mkDerivation {
    pname = "libxml2";
    version = "2.12.7";
    src = final.fetchurl {
      url = "https://gitlab.gnome.org/GNOME/libxml2/-/archive/v2.12.7/libxml2-v2.12.7.tar.gz";
      hash = "sha256-p8Enf06FmIP/OqoJpUVWG3UV4HipfrJAu5K/WgOuA/w=";
    };
    outputs = [
      "bin"
      "dev"
      "out"
    ];
    strictDeps = true;
    nativeBuildInputs = [
      final.pkg-config
      final.autoreconfHook
    ];
    buildInputs = [ final.zlib ];
    configureFlags = [
      "--exec-prefix=${placeholder "dev"}"
      "--without-python"
      "--without-icu"
      "--with-zlib"
    ];
    enableParallelBuilding = true;
    doCheck = false;
    postFixup = ''
      moveToOutput bin/xml2-config "$dev"
      moveToOutput lib/xml2Conf.sh "$dev"
    '';
    meta = {
      homepage = "https://gitlab.gnome.org/GNOME/libxml2";
      description = "XML parsing library for C (compat version for Viber)";
      license = prev.lib.licenses.mit;
      platforms = prev.lib.platforms.linux;
    };
  };

  # Override viber to use the compatible libxml2
  viber = prev.viber.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];

    # Replace system libxml2 with compat version in the RPATH library list
    libPath =
      builtins.replaceStrings
        [ (builtins.toString prev.libxml2.out) ]
        [ (builtins.toString final.libxml2-viber-compat.out) ]
        old.libPath;

    # Add libxshmfence to wrapper
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/viber \
        --prefix LD_LIBRARY_PATH : ${final.libxshmfence}/lib
    '';
  });
}
