{ config, pkgs, ... }:

# Claude Code only loads skills from ~/.claude/skills, so mirror the shared
# ~/.agents/skills collection into it as per-skill symlinks. The directory itself
# can't be a symlink because Claude Code keeps its own synced/ skills there.
let
  sync = pkgs.writeShellScript "sync-agent-skills" ''
    set -eu
    src="${config.home.homeDirectory}/.agents/skills"
    dst="${config.home.homeDirectory}/.claude/skills"
    mkdir -p "$dst"

    # Drop links into ~/.agents/skills whose skill was removed.
    for link in "$dst"/*; do
      [ -L "$link" ] || continue
      case "$(readlink -f "$link" || true)" in
        "$src"/*) [ -e "$link" ] || rm "$link" ;;
      esac
    done

    [ -d "$src" ] || exit 0
    for skill in "$src"/*/; do
      [ -f "$skill/SKILL.md" ] || continue
      name="$(basename "$skill")"
      # Leave real directories alone; only manage symlinks.
      if [ -e "$dst/$name" ] && [ ! -L "$dst/$name" ]; then
        continue
      fi
      ln -sfn "$src/$name" "$dst/$name"
    done
  '';
in
{
  home.activation.syncAgentSkills = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    run ${sync}
  '';

  # Re-sync when skills are added or removed, e.g. after `git -C ~/.agents pull`.
  systemd.user.services.sync-agent-skills = {
    Unit.Description = "Link ~/.agents/skills into ~/.claude/skills";
    Service = {
      Type = "oneshot";
      ExecStart = "${sync}";
    };
  };

  systemd.user.paths.sync-agent-skills = {
    Unit.Description = "Watch ~/.agents/skills for changes";
    Path = {
      PathChanged = "%h/.agents/skills";
      MakeDirectory = false;
    };
    Install.WantedBy = [ "paths.target" ];
  };
}
