# Function to set up Nix development shell environments
# Ported from zsh version

function _ncs_setup
  set -l lang $argv[1]
  set -l target_dir "$HOME/nixos/shells/$lang"
  
  if test -d "$target_dir"
    cp -r "$target_dir"/* "$PWD/"
    echo "use flake" > .envrc
    
    if test -d .git
      git add flake.lock flake.nix .envrc
      direnv allow
    end
    
    echo "Direnv for $lang has been set up. Happy coding!"
  else
    echo "No development shell found for $lang"
  end
end
