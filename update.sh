set -e
pushd ~/nixos
nixpkgs-fmt . &>/dev/null
git diff -U0 *.nix
echo "Rebuilding NixOS..."
sudo nixos-rebuild switch &>nixos-switch.log || (cat nixos-switch.log | rg error && false)
gen=$(nixos-rebuild list-generations | head -n 2 | tail -1 | awk '{print $1}')
git add .
git commit -m "$gen"
popd
