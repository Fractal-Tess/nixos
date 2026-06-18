final: prev: {
  uefi-firmware-parser = prev.uefi-firmware-parser.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ final.python3Packages.setuptools-scm ];
  });
}
