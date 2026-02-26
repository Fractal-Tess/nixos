final: prev:
let
  pythonPackages = prev.python313Packages;
  
  # Version and source for kimi-cli
  version = "1.15.0";
  src = prev.fetchFromGitHub {
    owner = "MoonshotAI";
    repo = "kimi-cli";
    rev = version;
    hash = "sha256-5iu3guqR0i3/1aLuwSCDdamxwkHdETk4RtLk8iW7CMY=";
  };

  # Build the web UI static files
  webUi = prev.buildNpmPackage {
    pname = "kimi-cli-web";
    inherit version;
    src = src + "/web";
    npmDepsHash = "sha256-CxpQr3aHS+l5CFeuBXMwGRdg4lG7Wxn10lg4YhYgwYA="; # Placeholder, will need to be updated
    
    buildPhase = ''
      runHook preBuild
      npm run build
      runHook postBuild
    '';
    
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist/* $out/
      runHook postInstall
    '';
  };
in
{
  # Python packages needed for kimi-cli
  python313 = prev.python313.override {
    packageOverrides = pyfinal: pyprev: {
      # Streaming JSON parser
      streamingjson = pythonPackages.buildPythonPackage rec {
        pname = "streamingjson";
        version = "0.0.5";
        pyproject = true;
        src = prev.fetchFromGitHub {
          owner = "karminski";
          repo = "streaming-json-py";
          rev = version;
          hash = "sha256-XKqW5gbK55OKoAWftoh5CmGc0Sn5FOvGKmrAbsEvIMo=";
        };
        build-system = [ pythonPackages.setuptools ];
        pythonImportsCheck = [ "streamingjson" ];
        meta = {
          description = "A streamlined, user-friendly JSON streaming preprocessor";
          homepage = "https://github.com/karminski/streaming-json-py";
          license = prev.lib.licenses.mit;
        };
      };

      # Python module for ripgrep
      ripgrepy = pythonPackages.buildPythonPackage rec {
        pname = "ripgrepy";
        version = "2.2.0";
        pyproject = true;
        src = prev.fetchFromGitHub {
          owner = "securisec";
          repo = "ripgrepy";
          rev = version;
          hash = "sha256-+Q9O6sLXgdhjxN6+cTJvNhVg6cr0jByETJrlpnc+FEQ=";
        };
        build-system = [
          pythonPackages.setuptools
          pythonPackages.wheel
        ];
        pythonImportsCheck = [ "ripgrepy" ];
        meta = {
          description = "Python module for ripgrep";
          homepage = "https://github.com/securisec/ripgrepy";
          license = prev.lib.licenses.gpl3Only;
        };
      };

      # Kosong - LLM abstraction layer (from kimi-cli repo)
      kosong = pythonPackages.buildPythonPackage {
        pname = "kosong";
        inherit version;
        pyproject = true;
        src = src + "/packages/kosong";
        build-system = [ pythonPackages.uv-build ];
        pythonRelaxDeps = true;
        dependencies = [
          pythonPackages.jsonschema
          pythonPackages.loguru
          pythonPackages.openai
          pythonPackages.pydantic
          pythonPackages.python-dotenv
          pythonPackages.typing-extensions
          pythonPackages.mcp
          pythonPackages.anthropic
          pythonPackages.google-genai
        ];
        meta = {
          description = "Streaming-first LLM-abstraction layer";
          homepage = "https://github.com/MoonshotAI/kimi-cli/tree/main/packages/kosong";
          license = prev.lib.licenses.asl20;
        };
      };

      # Kaos - OS abstraction layer (from kimi-cli repo)
      kaos = pythonPackages.buildPythonPackage {
        pname = "kaos";
        inherit version;
        pyproject = true;
        src = src + "/packages/kaos";
        build-system = [ pythonPackages.uv-build ];
        pythonRelaxDeps = true;
        postPatch = ''
          substituteInPlace pyproject.toml \
            --replace-fail "uv_build>=0.8.5,<0.9.0" "uv_build>=0.8.5,<0.10.0"
        '';
        dependencies = [
          pythonPackages.aiofiles
          pythonPackages.asyncssh
        ];
        meta = {
          description = "OS abstraction layer for agents";
          homepage = "https://github.com/MoonshotAI/kimi-cli/tree/main/packages/kaos";
          license = prev.lib.licenses.asl20;
        };
      };

      # Pykaos - alias for kaos
      pykaos = pyfinal.kaos;
    };
  };

  # Main kimi-cli package
  kimi-cli = pythonPackages.buildPythonApplication {
    pname = "kimi-cli";
    inherit version src;
    pyproject = true;

    build-system = [ pythonPackages.uv-build ];
    pythonRelaxDeps = true;

    # Copy the web UI static files to the package
    preBuild = ''
      mkdir -p src/kimi_cli/web/static
      cp -r ${webUi}/* src/kimi_cli/web/static/
    '';

    dependencies = [
      pythonPackages.kosong
      pythonPackages.pykaos
      pythonPackages.agent-client-protocol
      pythonPackages.aiofiles
      pythonPackages.aiohttp
      pythonPackages.typer
      pythonPackages.loguru
      pythonPackages.prompt-toolkit
      pythonPackages.pillow
      pythonPackages.pyyaml
      pythonPackages.rich
      pythonPackages.ripgrepy
      pythonPackages.streamingjson
      pythonPackages.trafilatura
      pythonPackages.lxml
      pythonPackages.tenacity
      pythonPackages.fastmcp
      pythonPackages.pydantic
      pythonPackages.httpx
      pythonPackages.tomlkit
      pythonPackages.jinja2
      pythonPackages.keyring
      # Web UI dependencies
      pythonPackages.fastapi
      pythonPackages.uvicorn
      pythonPackages.scalar-fastapi
      pythonPackages.websockets
      pythonPackages.setproctitle
    ];

    postFixup = ''
      wrapProgram $out/bin/kimi \
        --prefix PATH : ${prev.lib.makeBinPath [ prev.ripgrep ]} \
        --set KIMI_CLI_NO_AUTO_UPDATE "1"

      wrapProgram $out/bin/kimi-cli \
        --prefix PATH : ${prev.lib.makeBinPath [ prev.ripgrep ]} \
        --set KIMI_CLI_NO_AUTO_UPDATE "1"
    '';

    meta = {
      description = "Your next CLI agent by MoonshotAI";
      homepage = "https://github.com/MoonshotAI/kimi-cli";
      license = prev.lib.licenses.asl20;
      mainProgram = "kimi";
    };
  };
}
