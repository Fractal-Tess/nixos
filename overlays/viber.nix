self: super: {
  viber_patched = super.viber.overrideAttrs (old: {
    # Wrap the binary to include libxml2 in LD_LIBRARY_PATH
    installPhase = ''
      ${old.installPhase or ""}
      wrapProgram $out/bin/viber \
        --set LD_LIBRARY_PATH "${
          super.lib.makeLibraryPath [ super.libxml2 ]
        }:$LD_LIBRARY_PATH"
    '';
  });
}
