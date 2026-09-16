{ inputs }:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  lib = inputs.nixpkgs.lib;
  systemConfig =
    modules:
    (lib.nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      modules = modules ++ [ { system.stateVersion = "25.05"; } ];
    }).config;
  userConfig =
    modules:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = modules ++ [
        {
          home.username = "interface-test";
          home.homeDirectory = "/home/interface-test";
          home.stateVersion = "25.05";
        }
      ];
    }).config;
  containsPackage =
    package: packages: builtins.any (installed: installed.outPath == package.outPath) packages;
  programChecks =
    {
      name,
      flake,
      context,
    }:
    let
      isUser = context == "user";
      evaluate = if isUser then userConfig else systemConfig;
      module = if isUser then flake.homeManagerModules.default else flake.nixosModules.default;
      packages = config: if isUser then config.home.packages else config.environment.systemPackages;
      disabled = evaluate [ module ];
      enabled = evaluate [
        module
        { programs.${name}.enable = true; }
      ];
      overridden = evaluate [
        module
        {
          programs.${name} = {
            enable = true;
            package = pkgs.figlet;
          };
        }
      ];
      selected = enabled.programs.${name}.package;
    in
    {
      "${context}-${name}-disabled" = !containsPackage selected (packages disabled);
      "${context}-${name}-enabled" = containsPackage selected (packages enabled);
      "${context}-${name}-package-selection" =
        containsPackage pkgs.figlet (packages overridden)
        && !containsPackage selected (packages overridden);
    };
  serviceChecks =
    {
      name,
      flake,
      context,
      extra ? { },
    }:
    let
      isUser = context == "user";
      evaluate = if isUser then userConfig else systemConfig;
      module = if isUser then flake.homeManagerModules.default else flake.nixosModules.default;
      units =
        config:
        if isUser || name == "clip-sync" then config.systemd.user.services else config.systemd.services;
      wantedBy = unit: if isUser then unit.Install.WantedBy or [ ] else unit.wantedBy;
      disabled = evaluate [ module ];
      enabled = evaluate [
        module
        {
          services.${name} = extra // {
            enable = true;
          };
        }
      ];
      manual = evaluate [
        module
        {
          services.${name} = extra // {
            enable = true;
            autoStart = false;
          };
        }
      ];
    in
    {
      "${context}-${name}-disabled" = !(builtins.hasAttr name (units disabled));
      "${context}-${name}-automatic" = wantedBy (units enabled).${name} != [ ];
      "${context}-${name}-manual" =
        builtins.hasAttr name (units manual) && wantedBy (units manual).${name} == [ ];
    };
  templateFlake = (import ../templates/program-module/flake.nix).outputs {
    self = templateFlake;
    nixpkgs = inputs.nixpkgs;
  };
  programs = [
    {
      name = "asterveil";
      flake = inputs.asterveil;
    }
    {
      name = "omp";
      flake = inputs.oh-my-pi-flake;
    }
    {
      name = "responsively";
      flake = inputs.responsively-flake;
    }
    {
      name = "scorch";
      flake = inputs.scorch;
    }
    {
      name = "hello";
      flake = templateFlake;
    }
  ];
  services = [
    {
      name = "clip-sync";
      flake = inputs.clip-sync;
      context = "system";
    }
    {
      name = "clip-sync";
      flake = inputs.clip-sync;
      context = "user";
    }
    {
      name = "shadoword-api";
      flake = inputs.shadoword;
      context = "system";
    }
    {
      name = "shadoword-desktop";
      flake = inputs.shadoword;
      context = "user";
    }
    {
      name = "scorchd";
      flake = inputs.scorch;
      context = "system";
    }
    {
      name = "gitadel";
      flake = inputs.gitadel;
      context = "system";
    }
    {
      name = "open-design";
      flake = inputs.open-design-flake;
      context = "user";
      extra = {
        webFrontend.enable = true;
        mcp.enable = true;
      };
    }
  ];
  openDesignManual = userConfig [
    inputs.open-design-flake.homeManagerModules.default
    {
      services.open-design = {
        enable = true;
        autoStart = false;
        webFrontend.enable = true;
        mcp.enable = true;
      };
    }
  ];
  gitadelManual = systemConfig [
    inputs.gitadel.nixosModules.default
    {
      services.gitadel = {
        enable = true;
        autoStart = false;
        runner.enable = true;
      };
    }
  ];
  openDesignFacade = systemConfig [
    inputs.home-manager.nixosModules.default
    inputs.open-design-flake.nixosModules.default
    {
      users.users.interface-test.isNormalUser = true;
      home-manager.users.interface-test.home.stateVersion = "25.05";
      services.open-design = {
        enable = true;
        user = "interface-test";
        autoStart = false;
        port = 17457;
        environment.INTERFACE_TEST = "configured";
      };
    }
  ];
  checks = lib.foldl' (a: b: a // b) { } (
    lib.concatMap (
      program:
      map (context: programChecks (program // { inherit context; })) [
        "system"
        "user"
      ]
    ) programs
    ++ map serviceChecks services
    ++ [
      {
        open-design-manual-components =
          lib.all (unit: (unit.Install.WantedBy or [ ]) == [ ]) (
            builtins.attrValues openDesignManual.systemd.user.services
          )
          && lib.all (timer: (timer.Install.WantedBy or [ ]) == [ ]) (
            builtins.attrValues openDesignManual.systemd.user.timers
          );
        gitadel-manual-runner = lib.all (unit: unit.wantedBy == [ ]) (
          builtins.attrValues (
            lib.filterAttrs (name: _: lib.hasPrefix "gitadel" name) gitadelManual.systemd.services
          )
        );
        open-design-typed-user-facade =
          openDesignFacade.home-manager.users.interface-test.services.open-design.port == 17457
          &&
            (openDesignFacade.home-manager.users.interface-test.systemd.user.services.open-design.Install.WantedBy
              or [ ]
            ) == [ ];
      }
    ]
  );
  failures = builtins.attrNames (lib.filterAttrs (_: passed: !passed) checks);
in
assert lib.assertMsg (
  failures == [ ]
) "Application module contract failures: ${lib.concatStringsSep ", " failures}";
pkgs.writeText "application-interface-results.json" (builtins.toJSON checks)
