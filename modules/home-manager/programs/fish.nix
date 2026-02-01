{
  config,
  lib,
  pkgs,
  ...
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
        # tide configure --auto --style=Lean --prompt_colors='True color' --show_time='12-hour format' --lean_prompt_height='Two lines' --prompt_connection=Disconnected --prompt_spacing=Sparse --icons='Many icons' --transient=Yes
      } # Theme (uncomment after testing: tide configure)

      {
        name = "bass";
        src = pkgs.fishPlugins.bass.src;
      } # Fish function making it easy to use utilities written for Bash in Fish shell
      # {
      #   name = "pure";
      #   src = pkgs.fishPlugins.pure.src;
      # } # Alternative theme
      # {
      #   name = "sponge";
      #   src = pkgs.fishPlugins.sponge.src;
      # }
      # fish-ai - AI assistant plugin for fish shell
      # {
      #   name = "fish-ai";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "Realiserad";
      #     repo = "fish-ai";
      #     rev = "0193ac2f30a01939bb221ba6830bbea0e3271a3c";
      #     sha256 = "sha256-AQ5RbpnnSuX7z8kMrrjgHhS4StARu2BJVWz3V+RvQvo=";
      #   };
      # }
    ];

    # Shell abbreviations
    shellAbbrs = {
      # Standard aliases
      pcuptime = "uptime | awk '{print \$3}' | sed 's/,//'";
      cat = "bat";
      cc = "wl-copy --trim-newline";
      cv = "wl-paste --no-newline";
      diff = "batdiff";
      man = "batman";
      ll = "eza -l";
      ls = "eza";
      update = "~/nixos/update.sh";

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

      # Auto-start Hyprland on TTY1 if no Wayland session
      if status is-login
        and test -z "$WAYLAND_DISPLAY"
        and test "$XDG_VTNR" = "1"
        exec Hyprland
      end

      # NixOS Create Shell (ncs) - Function to set up dev environments
      function ncs
        if test -z "$argv[1]"
          echo "Usage: ncs <shell-type>"
          echo ""
          echo "Available shells:"
          ls ~/nixos/shells/
          return 1
        end

        set -l shell_type $argv[1]
        set -l shell_path "$HOME/nixos/shells/$shell_type"

        if test ! -d "$shell_path"
          echo "Error: Shell '$shell_type' not found in ~/nixos/shells/"
          echo ""
          echo "Available shells:"
          ls ~/nixos/shells/
          return 1
        end

        echo "Creating nix shell environment for: $shell_type"
        _ncs_setup $shell_type
        echo "Done! Environment ready."
      end

      # Helper function for ncs
      function _ncs_setup
        set -l lang $argv[1]
        set -l target_dir "$HOME/nixos/shells/$lang"

        if test ! -d "$target_dir"
          echo "No development shell found for $lang"
          return 1
        end

        # Copy flake.nix and flake.lock
        cp "$target_dir/flake.nix" "$PWD/"
        cp "$target_dir/flake.lock" "$PWD/"

        # Copy .envrc if it exists in the shell template
        if test -f "$target_dir/.envrc"
          cp "$target_dir/.envrc" "$PWD/"
        else
          # Create default .envrc
          echo "use flake" > .envrc
        end

        # Initialize git if not present
        if test ! -d .git
          git init
        end

        # Add files to git and allow direnv
        git add flake.lock flake.nix .envrc
        direnv allow

        echo "Direnv for $lang has been set up. Happy coding!"
      end

      # Nix Enter Shell (nec) - Enter a dev shell without copying files
      function nec
        if test -z "$argv[1]"
          echo "Usage: nec <shell-type>"
          echo ""
          echo "Available shells:"
          ls ~/nixos/shells/
          return 1
        end

        set -l shell_type $argv[1]
        set -l shell_path "$HOME/nixos/shells/$shell_type"

        if test ! -d "$shell_path"
          echo "Error: Shell '$shell_type' not found in ~/nixos/shells/"
          echo ""
          echo "Available shells:"
          ls ~/nixos/shells/
          return 1
        end

        echo "Entering nix dev shell for: $shell_type"
        nix develop "$shell_path"
      end
    '';
  };

  # fish-ai configuration file
  # See https://github.com/Realiserad/fish-ai for setup instructions
  # You'll need to add your API key to use the plugin
}
