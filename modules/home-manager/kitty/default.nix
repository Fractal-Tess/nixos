{ ... }: {
  programs.kitty = {
    enable = true;
    font = {
      package = null;
      # Download font from here https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/CascadiaCode.zip
      name = "CaskaydiaCoveNerdFont";
      size = 12;
    };
    settings = {
      scrollback_lines = 10000;
      # background_opacity = "0.85";
      background_opacity = "1.0";
      # background_blur = 64;
      update_check_interval = 0;
      enable_audio_bell = false;
      disable_ligatures = "never";
    };
    shellIntegration = {
      enableZshIntegration = true;
    };
  };
}
