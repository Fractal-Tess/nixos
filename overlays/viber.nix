self: super: {
  viber_patched = super.stdenv.mkDerivation {
    pname = "viber-patched";
    version = super.viber.version;

    buildInputs = [ super.makeWrapper ];
    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      # Copy the original binary
      cp ${super.viber}/bin/viber $out/bin/viber
      # Wrap it with the correct LD_LIBRARY_PATH
      wrapProgram $out/bin/viber \
        --set LD_LIBRARY_PATH "${
          super.lib.makeLibraryPath [ super.libxml2 ]
        }:$LD_LIBRARY_PATH"
    '';

    meta = super.viber.meta // {
      description = "Viber with libxml2 runtime fix";
    };
  };
}
