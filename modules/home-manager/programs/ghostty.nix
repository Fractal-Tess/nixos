{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      # Font configuration (matching kitty)
      "font-family" = "CaskaydiaCoveNerdFont";
      "font-size" = 12;

      # Scrollback (kitty: scrollback_lines = 10000)
      "scrollback-limit" = 10000;

      # Background opacity (kitty: background_opacity = "0.75")
      "background-opacity" = 0.75;

      # Background blur (kitty: background_blur = 96)
      "background-blur" = 96;

      "theme" = "GitHub Dark";

      # Bell (kitty: enable_audio_bell = false)
      # In Ghostty, we disable audio bell by not including it in bell-features

      # Ligatures (kitty: disable_ligatures = "never" means ligatures are enabled)
      # Ghostty enables ligatures by default via the 'calt' font feature
      # No need to explicitly configure this
    };
  };
}
