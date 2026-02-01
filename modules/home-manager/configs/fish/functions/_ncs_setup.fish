# Function to set up Nix development shell environments
# Ported from zsh version

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
