final: prev: {
  claude-flow = prev.buildNpmPackage rec {
    pname = "claude-flow";
    version = "2.0.0-alpha.90";

    src = prev.fetchFromGitHub {
      owner = "ruvnet";
      repo = "claude-flow";
      rev = "111288bf7f290136a7f1ee0ba55549071d6dacca";
      hash = "sha256-u02Xqj6wWxqTtpSOWEfuPBbYUl4bBPJNvGgA5WZKPaw=";
    };

    npmDepsHash = "sha256-Gpuvl8o8vvQd8uKJRte3YqY3ZzIyvXnTyC0iVDzWUMQ=";

    nodejs = prev.nodejs_22;

    nativeBuildInputs = with prev; [
      python3
      pkg-config
      sqlite.dev
    ];

    buildInputs = with prev; [
      sqlite
      libuv
    ] ++ prev.lib.optionals prev.stdenv.isDarwin [
      prev.darwin.apple_sdk.frameworks.CoreFoundation
      prev.darwin.apple_sdk.frameworks.Security
    ];

    env = {
      PYTHON = "${prev.python3}/bin/python";
      SQLITE3_LIB_DIR = "${prev.sqlite}/lib";  
      SQLITE3_INCLUDE_DIR = "${prev.sqlite.dev}/include";
      npm_config_build_from_source = "true";
      PUPPETEER_SKIP_DOWNLOAD = "1";
    };

    dontNpmBuild = true;
    dontNpmCheck = true;

    meta = with prev.lib; {
      description = "Enterprise-grade AI agent orchestration with ruv-swarm integration";
      longDescription = ''
        Claude-Flow v2 Alpha is an enterprise-grade AI orchestration platform that 
        combines hive-mind swarm intelligence, neural pattern recognition, and 87 
        advanced MCP tools for unprecedented AI-powered development workflows.
      '';
      homepage = "https://github.com/ruvnet/claude-flow";
      license = licenses.mit;
      maintainers = [ ];
      platforms = platforms.unix;
      mainProgram = "claude-flow";
    };
  };
}

