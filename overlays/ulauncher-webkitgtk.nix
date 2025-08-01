self: super: {
  ulauncher = super.ulauncher.overrideAttrs (old: {
    buildInputs =
      super.lib.lists.remove super.webkitgtk (old.buildInputs or [ ])
      ++ [ super.webkitgtk_4_1 ];
    propagatedBuildInputs =
      super.lib.lists.remove super.webkitgtk (old.propagatedBuildInputs or [ ])
      ++ [ super.webkitgtk_4_1 ];
  });
}
