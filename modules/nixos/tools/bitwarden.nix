{
  config,
  lib,
  pkgs,
  username,
  ...
}:

with lib;

let
  cfg = config.modules.tools.bitwarden;
  bw = "${pkgs.bitwarden-cli}/bin/bw";

  # secrets/bitwarden.json holds the master password. Until it exists the
  # vault needs a manual bw-agent-unlock; once it does, bw-agent unlocks itself.
  passwordSops = ../../../secrets/bitwarden.json;
  autoUnlock =
    cfg.autoUnlock && config.modules.services.sops.enable && builtins.pathExists passwordSops;
  passwordFile = config.sops.secrets.bitwarden_master_password.path;

  # The unlocked session key lives only in RAM ($XDG_RUNTIME_DIR, a per-user
  # tmpfs) and a transient user timer locks the vault again after a timeout.
  sessionFile = ''"''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bw-agent-session"'';

  unlock = pkgs.writeShellScriptBin "bw-agent-unlock" ''
    set -eu
    minutes="''${1:-60}"
    case "$minutes" in *[!0-9]* | "") echo "usage: bw-agent-unlock [minutes, 0 = until logout]" >&2; exit 2 ;; esac

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
    if [ "$minutes" = 0 ]; then
      echo "Vault unlocked for agents until logout or reboot (bw-agent-lock to lock now)."
      exit 0
    fi
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

  # What agents call: `bw` with the stored session, unlocking first when
  # the master password is available from sops.
  agent = pkgs.writeShellScriptBin "bw-agent" ''
    session_file=${sessionFile}
    if [ ! -s "$session_file" ]; then
      ${
        if autoUnlock then
          ''
            if ! ${bw} login --check >/dev/null 2>&1; then
              echo "Bitwarden CLI is not logged in. Ask the user to run: bw login" >&2
              exit 3
            fi
            session="$(${bw} unlock --raw --passwordfile ${passwordFile})" || exit 3
            (umask 077; printf '%s' "$session" > "$session_file")
            BW_SESSION="$session" ${bw} sync >/dev/null 2>&1 || true
          ''
        else
          ''
            echo "Bitwarden is locked. Ask the user to run: bw-agent-unlock [minutes]" >&2
            exit 3
          ''
      }
    fi
    BW_SESSION="$(cat "$session_file")" exec ${bw} "$@"
  '';
in
{
  options.modules.tools.bitwarden = {
    enable = mkEnableOption "Bitwarden CLI with time-limited agent unlock helpers" // {
      default = true;
    };
    autoUnlock =
      mkEnableOption "unlocking the vault for agents with the master password from secrets/bitwarden.json"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    sops.secrets = mkIf autoUnlock {
      bitwarden_master_password = {
        owner = username;
        group = username;
        mode = "0400";
        sopsFile = passwordSops;
        format = "json";
      };
    };

    environment.systemPackages = [
      pkgs.bitwarden-cli
      unlock
      lock
      agent
    ];
  };
}
