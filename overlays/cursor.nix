final: prev: {
  cursor = prev.cursor.overrideAttrs (oldAttrs:
    let codelldb = final.vscode-extensions.vadimcn.vscode-lldb;
    in rec {
      src = prev.fetchFromGitHub {
        owner = "getcursor";
        repo = "cursor";
        # gha-updater: LATEST="$(curl -Ls https://api.github.com/repos/getcursor/cursor/releases/latest)" && echo -n "$(echo $LATEST | jq -jr .tag_name) $(nix-prefetch-url --unpack $(echo $LATEST | jq -jr .tarball_url))"
        rev = "v0.4.0";
        sha256 =
          "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with actual hash
      };
      version = prev.lib.substring 1 20 src.rev;

      additionalLibs = with prev; [
        zlib # Required by CodeLLDB
        lldb # LLDB debugger
      ];

      patchCodeLLVM = prev.writeScript "patchCodeLLVM.sh" ''
        #!/usr/bin/env bash
        find ~/.cursor/extensions/ \
          -name codelldb \
          -type f -or -type l \
          -exec sh -c 'rm -f "$1" && ln -s "${codelldb}/${codelldb.installPrefix}/adapter/codelldb" "$1"' _ "{}" \;
      '';

      postInstall = oldAttrs.postInstall or "" + ''
        # Create a wrapper script for Cursor
        wrapProgram "$out/bin/cursor" \
          --run ${patchCodeLLVM} \
          --prefix LD_LIBRARY_PATH : "${
            prev.lib.makeLibraryPath additionalLibs
          }"
      '';

      buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ prev.makeWrapper ];
    });
}
