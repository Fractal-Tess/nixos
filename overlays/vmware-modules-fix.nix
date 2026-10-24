final: prev: {
  # patchelf 0.19 rewrites vmnet-natd with a PT_PHDR outside every PT_LOAD,
  # and glibc 2.44's loader segfaults on it, so vmware-networks fails to start
  # NAT on vmnet8 and every switch-to-configuration reports a failed unit.
  # auto-patchelf runs whichever `patchelf` is first on PATH; put 0.15.2 (what
  # nixpkgs used before 2026-10-20) ahead of the stdenv one.
  vmware-workstation = prev.vmware-workstation.overrideAttrs (old: {
    nativeBuildInputs = [
      (final.buildPackages.patchelf.overrideAttrs (_: {
        version = "0.15.2";
        src = final.fetchurl {
          url = "https://github.com/NixOS/patchelf/releases/download/0.15.2/patchelf-0.15.2.tar.bz2";
          hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
        };
        patches = [ ];
        doCheck = false;
      }))
    ]
    ++ old.nativeBuildInputs;
  });

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
