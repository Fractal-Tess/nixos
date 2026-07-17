self: super: {
  cliproxyapi = super.stdenv.mkDerivation {
    pname = "cliproxyapi";
    version = "7.2.83";

    src = super.fetchurl {
      url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v7.2.83/CLIProxyAPI_7.2.83_linux_amd64.tar.gz";
      hash = "sha256-c3D7XTn/3YhPeZ0mCROLVGXin0mIPua1Ia3umvITgIg=";
    };

    sourceRoot = ".";

    nativeBuildInputs = [ super.autoPatchelfHook ];

    installPhase = ''
      runHook preInstall
      install -Dm755 cli-proxy-api $out/bin/cliproxyapi
      runHook postInstall
    '';

    meta = with super.lib; {
      description = "Unified proxy that wraps AI CLI subscriptions (Codex, Claude, Grok) as OpenAI/Anthropic-compatible API";
      homepage = "https://github.com/router-for-me/CLIProxyAPI";
      license = licenses.mit;
      mainProgram = "cliproxyapi";
      platforms = [ "x86_64-linux" ];
    };
  };
}
