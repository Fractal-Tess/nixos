{
  lib,
  pkgs,
  ...
}:

{
  home.sessionPath = [ "/home/fractal-tess/.local/share/vite-plus/bin" ];

  home.activation.installVitePlus = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    VP_BIN="$HOME/.local/share/vite-plus/bin/vp"
    if [ ! -x "$VP_BIN" ]; then
      export PATH="${
        lib.makeBinPath [
          pkgs.curl
          pkgs.coreutils
          pkgs.gnutar
          pkgs.gzip
          pkgs.gnugrep
          pkgs.gnused
          pkgs.gawk
        ]
      }:$PATH"
      VP_NODE_MANAGER=no VP_PM_MANAGER=no \
        ${pkgs.bash}/bin/bash -c "$(${pkgs.curl}/bin/curl -fsSL https://vite.plus)"
    fi
  '';
}
