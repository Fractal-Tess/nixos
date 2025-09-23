{ ... }:

{
  # zsh
  home.file = {
    # Zsh config
    ".zshrc".source = ./.zshrc;

    # Zsh - p10k config
    ".p10k.zsh".source = ./.p10k.zsh;
  };
}