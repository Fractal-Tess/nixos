self: super: {
  ulauncher_patched = super.ulauncher.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ super.webkitgtk_4_0 ];
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/ulauncher \
        --set GI_TYPELIB_PATH "${super.webkitgtk_4_0}/lib/girepository-1.0"
    '';
  });
}
