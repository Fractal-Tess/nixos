final: prev:

let
  # patchelf 0.19 (nixpkgs since 2026-10-20) lays out some prebuilt binaries
  # with overlapping PT_LOAD segments or a PT_PHDR outside every PT_LOAD, and
  # glibc 2.44's loader segfaults on them. Both builders below run whichever
  # `patchelf` is first on PATH, so put 0.15.2 (the previous version) ahead
  # of the stdenv one.
  patchelf_0_15 = final.buildPackages.patchelf.overrideAttrs (_: {
    version = "0.15.2";
    src = final.fetchurl {
      url = "https://github.com/NixOS/patchelf/releases/download/0.15.2/patchelf-0.15.2.tar.bz2";
      hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
    };
    patches = [ ];
    doCheck = false;
  });

  withOldPatchelf =
    pkg:
    pkg.overrideAttrs (old: {
      nativeBuildInputs = [ patchelf_0_15 ] ++ (old.nativeBuildInputs or [ ]);
    });
in
{
  # vmnet-natd: vmware-networks failed to start NAT on vmnet8.
  vmware-workstation = withOldPatchelf prev.vmware-workstation;

  linuxPackages_latest = prev.linuxPackages_latest.extend (
    _: kprev: {
      # nvidia-smi, nvidia-powerd, nvidia-cuda-mps-control.
      nvidiaPackages = kprev.nvidiaPackages // {
        stable = withOldPatchelf kprev.nvidiaPackages.stable;
      };

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
