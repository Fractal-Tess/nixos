final: prev: {
  linuxPackages_latest = prev.linuxPackages_latest.extend (
    _: kprev: {
      vmware = kprev.vmware.overrideAttrs (old: {
        # The kernel module aggregator now expects a `.ko.cer` next to every
        # out-of-tree module. Other modules get one from kmodigest through the
        # kernel's common make flags, which vmware-modules does not use, so
        # the system's linux-modules build fails on vmmon/vmnet. Sign them
        # here the same way.
        nativeBuildInputs = old.nativeBuildInputs ++ [ final.buildPackages.kmodigest ];
        postInstall = (old.postInstall or "") + ''
          for module in "$out"/lib/modules/*/misc/*.ko; do
            kmodigest "$module"
          done
        '';
      });
    }
  );
}
