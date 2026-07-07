final: prev: {
  viber = prev.viber.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/viber \
        --prefix LD_LIBRARY_PATH : ${final.libxshmfence}/lib
    '';
  });
}
