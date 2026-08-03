final: _prev:

let
  version = "0.9.1";
  releaseBase = "https://github.com/Fractal-Tess/shadoword/releases/download/v${version}";

  mkShadowordBinary =
    {
      pname,
      asset,
      hash,
      executable,
      runtimeDeps,
      extraLibraryPath ? "",
    }:
    let
      wrappedLibraryPath = final.lib.concatStringsSep ":" (
        final.lib.filter (path: path != "") [
          (final.lib.makeLibraryPath runtimeDeps)
          extraLibraryPath
        ]
      );
    in
    final.stdenvNoCC.mkDerivation {
      inherit pname version;

      src = final.fetchurl {
        url = "${releaseBase}/${asset}";
        inherit hash;
      };

      nativeBuildInputs = [
        final.autoPatchelfHook
        final.makeWrapper
      ];
      buildInputs = runtimeDeps;
      autoPatchelfIgnoreMissingDeps = [ "libcuda.so.1" ];

      dontUnpack = true;

      installPhase = ''
        runHook preInstall

        mkdir -p unpacked "$out/bin" "$out/share/doc/${pname}"
        tar -xzf "$src" -C unpacked
        install -m755 "unpacked/bin/${executable}" "$out/bin/${executable}"
        install -m644 unpacked/README.md unpacked/CHANGELOG.md "$out/share/doc/${pname}/"

        wrapProgram "$out/bin/${executable}" \
          --prefix LD_LIBRARY_PATH : "${wrappedLibraryPath}"

        runHook postInstall
      '';

      meta = {
        description = "Offline speech-to-text with Whisper";
        homepage = "https://github.com/Fractal-Tess/shadoword";
        license = final.lib.licenses.mit;
        mainProgram = executable;
        platforms = [ "x86_64-linux" ];
        sourceProvenance = [ final.lib.sourceTypes.binaryNativeCode ];
      };
    };

  daemonRuntimeDeps = with final; [ stdenv.cc.cc.lib ];

  desktopRuntimeDeps = with final; [
    stdenv.cc.cc.lib
    alsa-lib
    fontconfig
    glib-networking
    gtk3
    libappindicator-gtk3
    libevdev
    libglvnd
    libopus
    libsoup_3
    libx11
    libxi
    libxtst
    libxcb
    libxkbcommon
    vulkan-loader
    wayland
    webkitgtk_4_1
    xdotool
  ];
in
{
  shadoword-api = mkShadowordBinary {
    pname = "shadoword-api";
    asset = "shadoword-api-cpu-x86_64-linux.tar.gz";
    hash = "sha256-oSHWW8iRoaAFbsdaZ/1jDkct5RVehf5JcNJBHZDfKqc=";
    executable = "shadoword-api";
    runtimeDeps = daemonRuntimeDeps;
  };

  shadoword-api-cuda = mkShadowordBinary {
    pname = "shadoword-api-cuda";
    asset = "shadoword-api-cuda-x86_64-linux.tar.gz";
    hash = "sha256-P+YDw6aYviguZOVoJM0uJBwroFUypJCldseTrwcuIDI=";
    executable = "shadoword-api";
    runtimeDeps =
      daemonRuntimeDeps
      ++ (with final.cudaPackages; [
        cuda_cudart
        libcublas
      ]);
    extraLibraryPath = "/run/opengl-driver/lib";
  };

  shadoword-api-vulkan = mkShadowordBinary {
    pname = "shadoword-api-vulkan";
    asset = "shadoword-api-vulkan-x86_64-linux.tar.gz";
    hash = "sha256-6C9INvZ+TsOzmvzvgqqDph256XHxnv+jx5qaLS5kFGA=";
    executable = "shadoword-api";
    runtimeDeps = daemonRuntimeDeps ++ [ final.vulkan-loader ];
    extraLibraryPath = "/run/opengl-driver/lib";
  };

  shadoword-desktop-client = mkShadowordBinary {
    pname = "shadoword-desktop-client";
    asset = "shadoword-desktop-client-x86_64-linux.tar.gz";
    hash = "sha256-CUur+WvjztAzNUBhCmrv4emMqxw4WDmvDgoy4VTLzFA=";
    executable = "shadoword-desktop";
    runtimeDeps = desktopRuntimeDeps;
    extraLibraryPath = "/run/opengl-driver/lib";
  };
}
