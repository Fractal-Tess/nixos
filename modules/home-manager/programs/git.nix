{ pkgs, config, ... }: {
  # git signing
  home.file.".ssh/allowed_signers".text =
    "* ${builtins.readFile /home/${config.home.username}/.ssh/id_ed25519.pub}";

  programs.git = {
    enable = true;
    lfs = { enable = true; };
    delta = {
      enable = true;
      options = {
        decorations = {
          commit-decoration-style = "bold yellow box ul";
          file-decoration-style = "none";
          file-style = "bold yellow ul";
        };
        features = "decorations";
        whitespace-error-style = "22 reverse";
      };
    };

    extraConfig = {
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519.pub";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
    };

    userEmail = "vgfractal@gmail.com";
    userName = "Fractal-Tess";
  };
}
