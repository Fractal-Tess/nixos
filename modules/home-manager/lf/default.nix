{ ... }: {
  programs.lf = {
    enable = true;
    keybindings = {
      D = "trash";
      U = "!du -sh";
      gg = null;
      gh = "cd ~";
      i = "$less $f";
    };
  };
}
