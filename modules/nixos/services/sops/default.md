# SOPS & age Key Management for NixOS

## What is SOPS?

[SOPS](https://github.com/getsops/sops) is a tool for managing secrets (passwords, API keys, etc.) in encrypted files. It integrates with NixOS (via sops-nix) to securely provide secrets to your system and services.

## Why use SOPS?

- **Keep secrets out of plaintext and version control**
- **Declarative secret management**
- **Integrates with NixOS for seamless secret delivery**

---

## Key Management

### 1. Generate a new age key

This is your private key for decrypting secrets. **Backup this file!**

```bash
nix-shell -p age
age-keygen -o ~/.config/sops/age/keys.txt
```

### 2. Convert an existing SSH key to age

If you want to use your SSH key for age encryption:

```bash
nix-shell -p ssh-to-age
mkdir -p ~/.config/sops/age
ssh-to-age -private-key -i ~/.ssh/id_ed25519 -o ~/.config/sops/age/keys.txt
```

### 3. Generate your age public key

Share this with collaborators or use it in your sops config for encryption.

```bash
nix-shell -p age
age-keygen -y ~/.config/sops/age/keys.txt > ~/.config/sops/age/keys.txt.pub
```

---

## Encrypting & Decrypting Files

### Encrypt a file (in-place)

```bash
sops -e -i secrets.yaml
```

### Decrypt a file (to stdout)

```bash
sops -d secrets.yaml
```

---

## SOPS Configuration Example (config/sops/config.yaml)

```yaml
creation_rules:
  - encrypted_regex: '^(data|stringData)$'
    age:
      - age1yourpublickeyhere
```

---

## Using Secrets in NixOS

1. **Reference your secrets file and key in your NixOS config:**
   ```nix
   sops.defaultSopsFile = ../../secrets/secrets.yaml;
   sops.defaultSopsFormat = "yaml";
   sops.age.keyFile = "/home/youruser/.config/sops/age/keys.txt";
   sops.secrets = {
     my_password = { };
   };
   ```
2. **Access the secret in a service:**
   The secret will be available at `/run/secrets/my_password`.

---

## Best Practices

- **Backup your private key!** Without it, you cannot decrypt your secrets.
- **Never commit your private key** to version control.
- **Only commit encrypted secrets** (never plaintext).
- **Rotate keys** if you suspect compromise.
- **Use strong, unique keys** for each environment if possible.

---

## Further Reading

- [sops-nix documentation](https://github.com/Mic92/sops-nix)
- [sops documentation](https://github.com/getsops/sops)
- [age documentation](https://github.com/FiloSottile/age)
