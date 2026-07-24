# Tenable Nessus on NixOS

Tenable distributes Nessus under a proprietary license from an EULA-gated
download. The NixOS module therefore manages the runtime environment and
systemd service, but does not download or redistribute Nessus itself.

1. Download the AMD64 Debian package from the official Tenable downloads page.
2. Extract its mutable `/opt/nessus` tree:

   ```sh
   tmp=$(sudo mktemp -d)
   sudo dpkg-deb -x ~/Downloads/Nessus-*.deb "$tmp"
   sudo cp -a "$tmp/opt/nessus" /opt/
   sudo rm -rf "$tmp"
   ```

3. Initialize the FIPS module and bundled core plugins:

   ```sh
   sudo systemctl stop nessusd
   sudo chmod 0700 /opt/nessus/bin/openssl
   sudo env OPENSSL_CONF=/opt/nessus/etc/ \
     /opt/nessus/bin/openssl fipsinstall \
     -out /opt/nessus/etc/nessus/fipsmodule.cnf \
     -module /opt/nessus/lib/nessus/fips.so \
     -self_test_oninstall
   sudo nessus-cli install /opt/nessus/var/nessus/plugins-core.tar.gz
   ```

4. Start the service:

   ```sh
   sudo systemctl start nessusd
   ```

   The module also installs `nessus-cli`, an FHS-wrapped version of Tenable's
   `nessuscli` for activation, updates, and diagnostics.

5. Complete setup at <https://localhost:8834>.

The firewall remains closed unless `modules.services.nessus.openFirewall` is
explicitly enabled. Nessus requires a real, writable `/opt/nessus` directory;
Tenable does not support replacing it with a symlink into the Nix store.
