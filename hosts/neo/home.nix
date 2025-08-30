{ pkgs, username, lib, ... }:

with lib;

{
  imports = [
    ../../modules/home-manager/default.nix
    ../../modules/home-manager/configs.nix
    ../../modules/home-manager/theming.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Baseline cli tools
    usbutils # USB device utilities
    lm_sensors # Hardware monitoring tools
    btop # Resource monitor with CPU, memory, disk, network
    trash-cli # Command line interface to FreeDesktop.org trash
    ddcutil # Monitor control utility (DDC/CI)
    sops # Secret management tool
    jq # Command-line JSON processor
    fzf # Command-line fuzzy finder
    ripgrep # Fast search tool (grep alternative)
    sd # Intuitive find & replace CLI
    procs # Modern replacement for ps
    ngrok # Expose local servers to the internet
    nmap # Network discovery and security auditing
    wakeonlan # Wake devices using Wake-on-LAN
    hping # Command-line TCP/IP packet assembler/analyzer
    oha # HTTP load generator
    lazygit # Simple terminal UI for git
    ffmpeg-full # Complete multimedia solution
    stress # Workload generator for system testing
    tokei # Count code statistics by language
    nitch # Lightweight system information fetch
    lolcat # Rainbow text output
    nh # Nix helper CLI (use system package to avoid ownership issues)
    hyperfine # Command-line benchmarking tool
    bleachbit # Disk space cleaner
    dust # Simple, quick, user-friendly disk usage analyzer

    # Build Tools
    gnumake # Build automation tool

    # File management
    xfce.thunar # File Manager
    mate.engrampa # Archive manager

    # === DEVELOPMENT TOOLS ===
    claude-code # AI code assistant
    nodejs_22 # JavaScript runtime
    bun # Fast, modern, all-in-one JavaScript runtime
    deno # JavaScript runtime
    gcc # GNU Compiler Collection
    clang-tools # C/C++ compiler toolchain

    # Language servers
    lua-language-server # Language server for Lua
    nixd # Language server for Nix
    svelte-language-server # Language server for Svelte
    emmet-language-server # Language server for Emmet
    tailwindcss-language-server # Language server for Tailwind CSS
    typescript-language-server # Language server for TypeScript
    astro-language-server # Language server for Astro
    vscode-langservers-extracted # HTML/CSS/JSON language servers

    # Formatters
    stylua # Formatter for Lua
    nixpkgs-fmt # Nix code formatter
    prettier # Code formatter for web technologies
    prettierd # Code formatter daemon for web technologies

  ];
}
