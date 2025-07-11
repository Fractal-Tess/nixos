self: super: {
  viber_patched = super.stdenv.mkDerivation {
    pname = "viber-patched";
    version = super.viber.version;

    buildInputs = [ super.makeWrapper ];
    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      # Remove the symlink if it exists
      rm -f $out/bin/viber
      # Create a wrapper script instead
      cat > $out/bin/viber <<EOF
      #!${super.stdenv.shell}
      export LD_LIBRARY_PATH="${
        super.lib.makeLibraryPath [ super.libxml2 ]
      }:$''${LD_LIBRARY_PATH:-}"
      exec -a "$0" "${super.viber}/opt/viber/Viber" "$@"
      EOF
      chmod +x $out/bin/viber
    '';

    meta = super.viber.meta // {
      description = "Viber with libxml2 runtime fix";
    };
  };
}
