self: super: {
  # Overlay for Kiro IDE (AI IDE based on VSCode)
  # Provides the 'kiro' package for x86_64-linux using a prebuilt tarball
  kiro = super.stdenv.mkDerivation rec {
    pname = "kiro";
    version = "0.1.0";

    # Download the official Kiro tarball
    src = super.fetchurl {
      url =
        "https://prod.download.desktop.kiro.dev/releases/202507140012--distro-linux-x64-tar-gz/202507140012-distro-linux-x64.tar.gz";
      sha256 = "sha256-6bbc/HndiN/HUoZyYo9r6Olih2n4/NMyRpxD59z9SH0=";
    };

    # Kiro tarball extracts to a directory named 'Kiro', and source root is set to that directory
    # So we copy from the current directory (.)
    installPhase = ''
      mkdir -p $out/opt
      cp -r . $out/opt/
      chmod +x $out/opt/kiro
      # Create a wrapper script in $out/bin
      mkdir -p $out/bin
      cat > $out/bin/kiro <<EOF
      #!${super.stdenv.shell}
      exec $out/opt/kiro "$@"
      EOF
      chmod +x $out/bin/kiro
    '';

    meta = with super.lib; {
      description = "The AI IDE for prototype to production built on VSCode";
      homepage = "https://kiro.dev";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "kiro";
      maintainers = [ ];
    };
  };
}
