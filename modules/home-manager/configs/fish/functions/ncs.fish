# NixOS Create Shell (ncs)
# Usage: ncs <shell-type>  (e.g., ncs python, ncs js, ncs rust)

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
