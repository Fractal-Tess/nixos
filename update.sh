set -e

pushd ~/nixos

nixpkgs-fmt . &>/dev/null

echo "Pulling latest changes from origin..."
git pull origin main || { echo "Failed to pull from origin. Please resolve conflicts or update your local branch."; exit 1; }

echo "Adding changes to git (before update)..."
git add .

echo "Showing diff..."
git diff -U0 **/*.nix

echo "Rebuilding NixOS with flake at ~/nixos..."
# Run nixos-rebuild, tee output to log and screen, fail on error, and show errors on screen as well as in log
if ! sudo nixos-rebuild switch --flake ~/nixos --show-trace --impure 2>&1 | tee nixos-switch.log; then
  echo "nixos-rebuild failed. Showing errors from nixos-switch.log:"
  rg error nixos-switch.log || true
  exit 1
fi

gen=$(nixos-rebuild list-generations | head -n 2 | tail -1 | awk '{print $1}')

echo "Committing changes (after successful update)..."
git commit -m "$gen"

# Try pushing to origin but don't fail if git exits with 1
echo "Trying to push commit to origin..."
git push origin main || echo "Failed to push to origin"

popd
