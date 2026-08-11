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
  home.activation = {
    installScorchSkill = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      rm -f "$HOME/.agents/skills/scorch/SKILL.md"
      install -Dm644 "${skill}/share/agent-skills/scorch/SKILL.md" \
        "$HOME/.agents/skills/scorch/SKILL.md"
    '';

    removeLegacyFirecrawlSkill = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -rf "$HOME/.agents/skills/firecrawl" "$HOME/.pi/agent/skills/firecrawl"
    '';
  };
}
