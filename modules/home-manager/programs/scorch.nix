{ lib, ... }:

{
  home.activation.removeLegacySearchSkills = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -rf \
      "$HOME/.agents/skills/firecrawl" \
      "$HOME/.agents/skills/scorch" \
      "$HOME/.pi/agent/skills/firecrawl"
  '';
}
