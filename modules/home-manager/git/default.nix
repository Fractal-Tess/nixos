{ ... }: {
  programs.git = {
    enable = true;
    aliases = {
      git = "git";
    };
    delta = {
      enable = true;
      options =
        {
          decorations = {
            commit-decoration-style = "bold yellow box ul";
            file-decoration-style = "none";
            file-style = "bold yellow ul";
          };
          features = "decorations";
          whitespace-error-style = "22 reverse";
        };
    };
    # signing = {
    #   signByDefault = true;
    # };

    userEmail = "vgfractal@gmail.com";
    userName = "Fractal-Tess";
  };

  programs.gitui = {
    enable = true;
  };
}
