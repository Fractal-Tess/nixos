{ config
, lib
, pkgs
, ...
}:

{
  programs.fish = {
    enable = true;
    package = pkgs.fish;

    # Use native Nix packages for fish plugins
    plugins = [
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      } # Directory jumping (zoxide alternative)
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      } # FZF integration
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      } # Notifications
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      } # Auto-pair brackets
      {
        name = "plugin-sudope";
        src = pkgs.fishPlugins.plugin-sudope.src;
      } # Sudo prefix (Esc+Esc)
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit.src;
      } # Interactive git -- cool
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      } # Theme (uncomment after testing: tide configure)
      # {
      #   name = "pure";
      #   src = pkgs.fishPlugins.pure.src;
      # } # Alternative theme
      # {
      #   name = "sponge";
      #   src = pkgs.fishPlugins.sponge.src;
      # }
      # fish-ai - AI assistant plugin for fish shell
      {
        name = "fish-ai";
        src = pkgs.fetchFromGitHub {
          owner = "Realiserad";
          repo = "fish-ai";
          rev = "0193ac2f30a01939bb221ba6830bbea0e3271a3c";
          sha256 = "sha256-AQ5RbpnnSuX7z8kMrrjgHhS4StARu2BJVWz3V+RvQvo=";
        };
      }
    ];

    # Shell abbreviations
    shellAbbrs = {
      # Standard aliases
      pcuptime = "uptime | awk '{print \$3}' | sed 's/,//'";
      cat = "bat";
      cc = "clipcopy";
      diff = "batdiff";
      man = "batman";
      ll = "eza -l";
      ls = "eza";
      update = "~/nixos/update.sh";

      # Dev environment setup
      ncs-csharp = "_ncs_setup csharp";
      ncs-go = "_ncs_setup go";
      ncs-java = "_ncs_setup java";
      ncs-maui = "_ncs_setup maui";
      ncs-php = "_ncs_setup php";
      ncs-nodejs = "_ncs_setup node";
      ncs-python3 = "_ncs_setup python3";
      ncs-react-native = "_ncs_setup react-native";
      ncs-rust = "_ncs_setup rust";
      ncs-tauri = "_ncs_setup tauri";
      ncs-unity = "_ncs_setup unity";

      # Nix develop shortcuts
      nas-c = "nix develop ~/nixos/shells/c";
      nas-csharp = "nix develop ~/nixos/shells/csharp";
      nas-go = "nix develop ~/nixos/shells/go";
      nas-java = "nix develop ~/nixos/shells/java";
      nas-maui = "nix develop ~/nixos/shells/maui";
      nas-php = "nix develop ~/nixos/shells/php";
      nas-nodejs = "nix develop ~/nixos/shells/node";
      nas-python3 = "nix develop ~/nixos/shells/python3";
      nas-react-native = "nix develop ~/nixos/shells/react-native";
      nas-rust = "nix develop ~/nixos/shells/rust";
      nas-tauri = "nix develop ~/nixos/shells/tauri";
      nas-unity = "nix develop ~/nixos/shells/unity";

      # AI tools
      zai = "~/nixos/scripts/claude-code/z-ai.sh";
      minimax = "~/nixos/scripts/claude-code/minimax.sh";
      ca = "cursor-agent";
    };

    # Interactive shell initialization
    interactiveShellInit = ''
      # Disable greeting message
      set fish_greeting

      # Load custom secrets (conditional)
      if test -f ~/.secrets.fish
        source ~/.secrets.fish
      end

      # Add scripts to PATH
      if test -d ~/nixos/scripts
        fish_add_path ~/nixos/scripts
      end

      # pnpm configuration
      if test -d "$PNPM_HOME"
        fish_add_path "$PNPM_HOME"
      end

      # Auto-start Hyprland on TTY1 if no Wayland session
      if status is-login
        and test -z "$WAYLAND_DISPLAY"
        and test "$XDG_VTNR" = "1"
        exec Hyprland
      end

      # Cursor trace integration
      if test -n "$CURSOR_TRACE_ID"
        set -g PROMPT_EOL_MARK ""
        if test -f "$HOME/.iterm2_shell_integration.fish"
          source "$HOME/.iterm2_shell_integration.fish"
        end
      end

      # Install fish-ai Python package and create bin symlink if needed
      if not test -d ~/.local/share/fish-ai/.venv
        mkdir -p ~/.local/share/fish-ai
        cd ~/.local/share/fish-ai
        uv venv
        source .venv/bin/activate
        uv pip install git+https://github.com/Realiserad/fish-ai.git 2>/dev/null || true
        deactivate
      end

      # Create bin symlink for fish-ai if it doesn't exist
      if test -d ~/.local/share/fish-ai/.venv/bin -a ! -d ~/.local/share/fish-ai/bin
        mkdir -p ~/.local/share/fish-ai/bin
        for f in ~/.local/share/fish-ai/.venv/bin/*
          if test -f "$f"
            ln -sf "$f" ~/.local/share/fish-ai/bin/(basename "$f") 2>/dev/null || true
          end
        end
      end

      # Add fish-ai bin to PATH if it exists
      if test -d ~/.local/share/fish-ai/bin
        fish_add_path ~/.local/share/fish-ai/bin
      end
    '';
  };

  # fish-ai configuration file
  # See https://github.com/Realiserad/fish-ai for setup instructions
  # You'll need to add your API key to use the plugin
}
