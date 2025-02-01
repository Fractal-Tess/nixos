set -e

sleep_function() {
  sleep 2
}
pushd ~/nixos

nixpkgs-fmt . &>/dev/null

# Pull the latest changes from the origin and fail if there are conflicts or the tree is out of date
echo "Pulling latest changes from origin..."
sleep_function
git pull origin main || { echo "Failed to pull from origin. Please resolve conflicts or update your local branch."; exit 1; }

echo "Showing diff..."
sleep_function
git diff -U0 **/*.nix

echo "Rebuilding NixOS with flake at ~/nixos..."
sleep_function
sudo nixos-rebuild switch --flake ~/nixos --show-trace | tee nixos-switch.log || (cat nixos-switch.log | rg error && false)

gen=$(nixos-rebuild list-generations | head -n 2 | tail -1 | awk '{print $1}')

echo "Adding changes to git..."
sleep_function
git add .

echo "Committing changes..."
sleep_function
git commit -m "$gen"

# try pushing to origin but don't fail if git exists with 1
# print a message if it fails
echo "Trying to push commit to origin..."
sleep_function
git push origin main || echo "Failed to push to origin"

popd
