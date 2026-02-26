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
    npmDepsHash = "sha256-CxpQr3aHS+l5CFeuBXMwGRdg4lG7Wxn10lg4YhYgwYA=";
    
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
      # scalar-fastapi - override to disable pytest (no tests but pytest fails)
      scalar-fastapi = pyprev.scalar-fastapi.overridePythonAttrs (oldAttrs: {
        doCheck = false;
        dontUsePytestCheck = true;
      });

      # Streaming JSON parser
      streamingjson = pyfinal.buildPythonPackage rec {
        pname = "streamingjson";
        version = "0.0.5";
        pyproject = true;
        src = prev.fetchFromGitHub {
          owner = "karminski";
          repo = "streaming-json-py";
          rev = version;
          hash = "sha256-XKqW5gbK55OKoAWftoh5CmGc0Sn5FOvGKmrAbsEvIMo=";
        };
        build-system = [ pyfinal.setuptools ];
        pythonImportsCheck = [ "streamingjson" ];
        meta = {
          description = "A streamlined, user-friendly JSON streaming preprocessor";
          homepage = "https://github.com/karminski/streaming-json-py";
          license = prev.lib.licenses.mit;
        };
      };

      # Python module for ripgrep
      ripgrepy = pyfinal.buildPythonPackage rec {
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
          pyfinal.setuptools
          pyfinal.wheel
        ];
        pythonImportsCheck = [ "ripgrepy" ];
        meta = {
          description = "Python module for ripgrep";
          homepage = "https://github.com/securisec/ripgrepy";
          license = prev.lib.licenses.gpl3Only;
        };
      };

      # Kosong - LLM abstraction layer (from kimi-cli repo)
      kosong = pyfinal.buildPythonPackage {
        pname = "kosong";
        inherit version;
        pyproject = true;
        src = src + "/packages/kosong";
        build-system = [ pyfinal.setuptools pyfinal.wheel ];
        pythonRelaxDeps = true;
        prePatch = ''
          # Replace uv_build with setuptools in pyproject.toml
          substituteInPlace pyproject.toml \
            --replace-fail 'requires = ["uv_build>=0.8.5,<0.10.0"]' 'requires = ["setuptools"]' \
            --replace-fail 'build-backend = "uv_build"' 'build-backend = "setuptools.build_meta"'
        '';
        dependencies = [
          pyfinal.jsonschema
          pyfinal.loguru
          pyfinal.openai
          pyfinal.pydantic
          pyfinal.python-dotenv
          pyfinal.typing-extensions
          pyfinal.mcp
          pyfinal.anthropic
          pyfinal.google-genai
        ];
        meta = {
          description = "Streaming-first LLM-abstraction layer";
          homepage = "https://github.com/MoonshotAI/kimi-cli/tree/main/packages/kosong";
          license = prev.lib.licenses.asl20;
        };
      };

      # Kaos - OS abstraction layer (from kimi-cli repo)
      kaos = pyfinal.buildPythonPackage {
        pname = "kaos";
        inherit version;
        pyproject = true;
        src = src + "/packages/kaos";
        build-system = [ pyfinal.setuptools pyfinal.wheel ];
        pythonRelaxDeps = true;
        prePatch = ''
          # Replace uv_build with setuptools in pyproject.toml
          substituteInPlace pyproject.toml \
            --replace-fail 'requires = ["uv_build>=0.8.5,<0.9.0"]' 'requires = ["setuptools"]' \
            --replace-fail 'build-backend = "uv_build"' 'build-backend = "setuptools.build_meta"'
        '';
        dependencies = [
          pyfinal.aiofiles
          pyfinal.asyncssh
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

    build-system = [ pythonPackages.setuptools pythonPackages.wheel ];
    pythonRelaxDeps = true;
    
    prePatch = ''
      # Replace uv_build with setuptools in pyproject.toml
      substituteInPlace pyproject.toml \
        --replace-fail 'requires = ["uv_build>=0.8.5,<0.10.0"]' 'requires = ["setuptools"]' \
        --replace-fail 'build-backend = "uv_build"' 'build-backend = "setuptools.build_meta"'
    '';

    patches = [ ./fix-worker-path.patch ];

    # Patch the worker path before build
    preBuild = ''
      substituteInPlace src/kimi_cli/web/runner/process.py \
        --replace-fail "@kimiCli@" "$out/bin/kimi-cli"
    '';
    
    # Copy the web UI static files after installation
    postInstall = ''
      mkdir -p $out/lib/python3.13/site-packages/kimi_cli/web/static
      cp -r ${webUi}/* $out/lib/python3.13/site-packages/kimi_cli/web/static/
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
