{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.tools.bitwarden;
  bw = "${pkgs.bitwarden-cli}/bin/bw";

  # The unlocked session key lives only in RAM ($XDG_RUNTIME_DIR, a per-user
  # tmpfs) and a transient user timer locks the vault again after a timeout.
  sessionFile = ''"''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bw-agent-session"'';

  unlock = pkgs.writeShellScriptBin "bw-agent-unlock" ''
    set -eu
    minutes="''${1:-60}"
    case "$minutes" in *[!0-9]* | "") echo "usage: bw-agent-unlock [minutes]" >&2; exit 2 ;; esac

    if ! ${bw} login --check >/dev/null 2>&1; then
      echo "Not logged in. Run: bw login" >&2
      exit 1
    fi

    session="$(${bw} unlock --raw)"
    umask 077
    printf '%s' "$session" > ${sessionFile}
    BW_SESSION="$session" ${bw} sync >/dev/null

    ${pkgs.systemd}/bin/systemctl --user stop bw-agent-lock.timer bw-agent-lock.service >/dev/null 2>&1 || true
    ${pkgs.systemd}/bin/systemctl --user reset-failed bw-agent-lock.service >/dev/null 2>&1 || true
    ${pkgs.systemd}/bin/systemd-run --user --quiet --collect \
      --unit=bw-agent-lock --on-active="''${minutes}m" \
      ${lock}/bin/bw-agent-lock
    echo "Vault unlocked for agents for $minutes minutes (bw-agent-lock to lock now)."
  '';

  lock = pkgs.writeShellScriptBin "bw-agent-lock" ''
    rm -f ${sessionFile}
    ${bw} lock >/dev/null 2>&1 || true
    ${pkgs.systemd}/bin/systemctl --user stop bw-agent-lock.timer >/dev/null 2>&1 || true
    echo "Vault locked."
  '';

  # What agents call: `bw` with the session from bw-agent-unlock, if any.
  agent = pkgs.writeShellScriptBin "bw-agent" ''
    if [ ! -s ${sessionFile} ]; then
      echo "Bitwarden is locked. Ask the user to run: bw-agent-unlock [minutes]" >&2
      exit 3
    fi
    BW_SESSION="$(cat ${sessionFile})" exec ${bw} "$@"
  '';
in
{
  options.modules.tools.bitwarden = {
    enable = mkEnableOption "Bitwarden CLI with time-limited agent unlock helpers" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.bitwarden-cli
      unlock
      lock
      agent
    ];
  };
}
