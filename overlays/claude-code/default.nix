final: prev: {
  claude-code = prev.buildNpmPackage rec {
    pname = "claude-code";
    version = "2.1.98";

    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-9mziiXKmfYXB5dDpw+M5K9fDb3bsJcO/l0r3hKK9VZ0=";
    };

    npmDepsHash = "sha256-WPSk0pYCr2WGM8vQpbbIDs3oZ2j3iIKxnFgePvXztr8=";

    strictDeps = true;

    postPatch = ''
      cp ${./package-lock.json} package-lock.json
      substituteInPlace cli.js \
        --replace-fail '#!/bin/sh' '#!/usr/bin/env sh'
    '';

    dontNpmBuild = true;

    env.AUTHORIZED = "1";

    postInstall = ''
      wrapProgram $out/bin/claude \
        --set DISABLE_AUTOUPDATER 1 \
        --set-default FORCE_AUTOUPDATE_PLUGINS 1 \
        --set DISABLE_INSTALLATION_CHECKS 1 \
        --unset DEV \
        --prefix PATH : ${
          prev.lib.makeBinPath (
            [
              prev.procps
            ]
            ++ prev.lib.optionals prev.stdenv.hostPlatform.isLinux [
              prev.bubblewrap
              prev.socat
            ]
          )
        }
    '';

    meta = with prev.lib; {
      description = "Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
      homepage = "https://github.com/anthropics/claude-code";
      license = licenses.unfree;
      mainProgram = "claude";
    };
  };
}
