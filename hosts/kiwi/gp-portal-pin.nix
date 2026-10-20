{ pkgs, ... }:

#============================================================================
# CARRIERX GLOBALPROTECT PORTAL PIN
#============================================================================
# gpvpn.carrierx.com resolves to two firewalls that keep separate SAML state.
# A login is spread over several processes (gpclient, its WebKit login window,
# NetworkManager's auth dialog) that each resolve the name on their own, so
# one login can land on both firewalls and fail. This keeps the name pinned in
# /etc/hosts to one firewall that completes a TLS handshake, and moves the pin
# to the other one only when the pinned firewall stops answering. A bare
# handshake does not start a portal login, so it never shows in portal logs.

let
  pin = pkgs.writeShellApplication {
    name = "gp-portal-pin";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      gnused
      openssl
      systemd
    ];
    text = ''
      host=gpvpn.carrierx.com
      marker="# gp-portal-pin"

      healthy() {
        timeout 5 openssl s_client -connect "$1:443" -servername "$host" \
          -verify_hostname "$host" -verify_return_error </dev/null >/dev/null 2>&1
      }

      current=$(awk -v m="$marker" 'index($0, m) { print $1 }' /etc/hosts)
      if [ -n "$current" ] && healthy "$current"; then
        exit 0
      fi

      # Real DNS answers, ignoring the pin itself
      mapfile -t ips < <(resolvectl query --legend=no --synthesize=no "$host" 2>/dev/null |
        grep -oE '[0-9]+(\.[0-9]+){3}' | shuf)

      for ip in "''${ips[@]}"; do
        [ "$ip" = "$current" ] && continue
        if healthy "$ip"; then
          sed -i "/$marker\$/d" /etc/hosts
          echo "$ip $host $marker" >>/etc/hosts
          echo "Pinned $host to $ip"
          exit 0
        fi
      done

      # Nothing healthy: drop the pin and fall back to plain DNS
      if [ -n "$current" ]; then
        sed -i "/$marker\$/d" /etc/hosts
        echo "No healthy portal node, removed pin to $current"
      fi
    '';
  };
in
{
  # The pin is written at runtime, so /etc/hosts must be a real file
  environment.etc.hosts.mode = "0644";

  systemd.services.gp-portal-pin = {
    description = "Pin the CarrierX GlobalProtect portal to one healthy firewall";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pin}/bin/gp-portal-pin";
    };
  };

  systemd.timers.gp-portal-pin = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15s";
      OnUnitActiveSec = "30s";
      AccuracySec = "5s";
    };
  };

  # A rebuild rewrites /etc/hosts; restore the pin right after switching
  system.activationScripts.gp-portal-pin = {
    deps = [ "etc" ];
    text = ''
      ${pkgs.systemd}/bin/systemctl start --no-block gp-portal-pin.service || true
    '';
  };
}
