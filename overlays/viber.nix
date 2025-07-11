self: super: {
  viber_patched = super.viber.overrideAttrs (old: {
    preFixup = ''
      wrapProgram $out/bin/viber \
        --set LD_LIBRARY_PATH "${
          super.lib.makeLibraryPath [ super.libxml2 ]
        }:$LD_LIBRARY_PATH"
    '';
  });
}
