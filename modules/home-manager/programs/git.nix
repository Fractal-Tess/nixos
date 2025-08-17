{ config, ... }: {
  # git signing
  home.file.".ssh/allowed_signers".text =
    "* ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."; # Replace with actual key content

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
      init.defaultBranch = "main";
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "/home/fractal-tess/.ssh/id_ed25519.pub";
      gpg.ssh.allowedSignersFile = "/home/fractal-tess/.ssh/allowed_signers";
    };

    userEmail = "vgfractal@gmail.com";
    userName = "Fractal-Tess";
  };
}
