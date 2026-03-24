final: prev: {
  netbird = prev.netbird.overrideAttrs (old: {
    preBuild =
      (old.preBuild or "")
      + ''
        # Fix go1.25/1.26 gvisor vendor conflict by making vendor writable and removing the conflicting file
        chmod -R u+w vendor/gvisor.dev/gvisor/pkg/sync/
        rm -f vendor/gvisor.dev/gvisor/pkg/sync/runtime_constants_go126.go
      '';
  });
}
