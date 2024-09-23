set -e
pushd ~/nixos

nixpkgs-fmt . &>/dev/null
git diff -U0 **/*.nix

echo "Rebuilding NixOS with flake at ~/nixos..."

sudo nixos-rebuild switch --flake ~/nixos &>nixos-switch.log || (cat nixos-switch.log | rg error && false)

gen=$(nixos-rebuild list-generations | head -n 2 | tail -1 | awk '{print $1}')

git add .
git commit -m "$gen"

# try pushing to origin but don't fail if git exists with 1
# print a message if it fails
echo "Trying to push commit to origin..."
git push origin main || echo "Failed to push to origin"

popd
