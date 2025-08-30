{ pkgs, username, lib, ... }:

with lib;

{
  #============================================================================
  # IMPORTS
  #============================================================================

  imports = [
    ../../modules/home-manager/default.nix
    ../../modules/home-manager/configs.nix
    ../../modules/home-manager/theming.nix
  ];

  #============================================================================
  # HOME MANAGER CONFIGURATION
  #============================================================================

  # Basic home configuration
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "24.05"; # Don't change this
  };

  # Enable Home Manager self-management
  programs.home-manager.enable = true;

  #============================================================================
  # GNOME KEYRING CONFIGURATION
  #============================================================================

  # GNOME Keyring daemon for secrets management
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" "ssh" ];
  };

  #============================================================================
  # USER PACKAGES
  #============================================================================

  home.packages = with pkgs; [

    #--------------------------------------------------------------------------
    # SYSTEM UTILITIES
    #--------------------------------------------------------------------------

    # Hardware monitoring and control
    lm_sensors # Hardware monitoring tools
    btop # Resource monitor with CPU, memory, disk, network
    ddcutil # Monitor control utility (DDC/CI)
    usbutils # USB device utilities

    # File system tools
    bleachbit # Disk space cleaner
    dust # Simple, quick, user-friendly disk usage analyzer
    trash-cli # FreeDesktop.org trash interface

    # File managers
    xfce.thunar # Lightweight file manager

    # Archive management
    mate.engrampa # Archive manager

    # Search and text processing
    fzf # Command-line fuzzy finder
    ripgrep # Fast search tool (grep alternative)
    sd # Intuitive find & replace CLI
    jq # Command-line JSON processor

    # Process management
    procs # Modern replacement for ps

    # Security and secrets
    sops # Secret management tool

    #--------------------------------------------------------------------------
    # NETWORKING TOOLS
    #--------------------------------------------------------------------------

    ngrok # Expose local servers to the internet
    nmap # Network discovery and security auditing
    wakeonlan # Wake devices using Wake-on-LAN
    hping # TCP/IP packet assembler/analyzer
    oha # HTTP load generator

    #--------------------------------------------------------------------------
    # DEVELOPMENT TOOLS
    #--------------------------------------------------------------------------

    # AI assistants
    claude-code # AI code assistant

    # Programming languages and runtimes
    nodejs_22 # JavaScript runtime
    bun # Fast, modern, all-in-one JavaScript runtime
    deno # JavaScript runtime
    gcc # GNU Compiler Collection
    clang-tools # C/C++ compiler toolchain

    # Build tools
    gnumake # Build automation tool

    # Development utilities
    hyperfine # Command-line benchmarking tool
    tokei # Count code statistics by language

    # Version control
    lazygit # Simple terminal UI for git

    #--------------------------------------------------------------------------
    # LANGUAGE SERVERS & FORMATTERS
    #--------------------------------------------------------------------------

    # Language servers
    lua-language-server # Language server for Lua
    nixd # Language server for Nix
    svelte-language-server # Language server for Svelte
    emmet-language-server # Language server for Emmet
    tailwindcss-language-server # Language server for Tailwind CSS
    typescript-language-server # Language server for TypeScript
    astro-language-server # Language server for Astro
    vscode-langservers-extracted # HTML/CSS/JSON language servers

    # Code formatters
    stylua # Formatter for Lua
    nixpkgs-fmt # Nix code formatter
    prettier # Code formatter for web technologies
    prettierd # Code formatter daemon for web technologies

    #--------------------------------------------------------------------------
    # MULTIMEDIA TOOLS
    #--------------------------------------------------------------------------

    # Audio/Video processing
    ffmpeg-full # Complete multimedia solution

    #--------------------------------------------------------------------------
    # TERMINAL ENHANCEMENTS
    #--------------------------------------------------------------------------

    nitch # Lightweight system information fetch
    lolcat # Rainbow text output
    nh # Nix helper CLI
    stress # Workload generator for system testing

    #--------------------------------------------------------------------------
    # LAPTOP-SPECIFIC TOOLS
    #--------------------------------------------------------------------------

    # Note: This is a minimal configuration for the neo laptop
    # Additional packages are kept to minimum for better performance
    # and battery life
  ];
}
