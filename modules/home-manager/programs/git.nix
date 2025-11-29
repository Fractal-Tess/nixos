{ config, ... }: {
  programs.git = {
    enable = true;
    lfs = { enable = true; };

    settings = {
      init.defaultBranch = "main";
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "/home/fractal-tess/.ssh/id_ed25519.pub";
      gpg.ssh.allowedSignersFile = "/home/fractal-tess/.ssh/allowed_signers";
      user.email = "vgfractal@gmail.com";
      user.name = "Fractal-Tess";
      credential.helper = "/etc/profiles/per-user/fractal-tess/bin/git-credential-netrc -f /home/fractal-tess/.netrc";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
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
}
