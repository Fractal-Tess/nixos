# Generating keys

## Generate a new key

```bash
nix-shell -p age
age-keygen -o ~/.config/sops/age/keys.txt
```

## Convert SSH key to age

```bash
nix-shell -p ssh-to-age
mkdir ~/.config/sops/age -p
ssh-to-age -private-key -i ~/.ssh/id_ed25519 -o ~/.config/sops/age/keys.txt
```

## Generate public key

```bash
nix-shell -p age
age-keygen -y ~/.config/sops/age/keys.txt > ~/.config/sops/age/keys.txt.pub
```
