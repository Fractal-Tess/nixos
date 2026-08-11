{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  skill = inputs.scorch.packages.${pkgs.stdenv.hostPlatform.system}.skill;
in
{
  home.file = {
    ".agents/skills/scorch/SKILL.md".source = "${skill}/share/agent-skills/scorch/SKILL.md";
  };

  home.activation.removeLegacyFirecrawlSkill = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -rf "$HOME/.agents/skills/firecrawl" "$HOME/.pi/agent/skills/firecrawl"
  '';
}
