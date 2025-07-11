self: super: {
  viber_patched = super.stdenv.mkDerivation {
    pname = "viber-patched";
    version = super.viber.version;

    buildInputs = [ super.makeWrapper ];
    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cat > $out/bin/viber <<EOF
      #!${super.stdenv.shell}
      export LD_LIBRARY_PATH="${
        super.lib.makeLibraryPath [ super.libxml2 ]
      }:$''${LD_LIBRARY_PATH:-}"
      exec -a "$0" "${super.viber}/bin/viber" "$@"
      EOF
      chmod +x $out/bin/viber
    '';

    meta = super.viber.meta // {
      description = "Viber with libxml2 runtime fix";
    };
  };
}
