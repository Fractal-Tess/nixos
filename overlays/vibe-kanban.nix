self: super: {
  vibe-kanban = super.stdenv.mkDerivation {
    pname = "vibe-kanban";
    version = "0.1.30";

    src = super.fetchurl {
      url = "https://github.com/BloopAI/vibe-kanban/releases/download/v0.1.30-20260313160158/Vibe.Kanban_0.1.30_amd64.AppImage";
      hash = "sha256-YJwe6ZspC5OCPSemB+l68khtxbWdUzhK9QWx6Cw6f2k=";
    };

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/opt $out/share/applications
      cp $src $out/opt/Vibe.Kanban.AppImage
      chmod +x $out/opt/Vibe.Kanban.AppImage

      cat > $out/bin/vibe-kanban <<EOF
      #!${super.stdenv.shell}
      exec ${super.appimage-run}/bin/appimage-run $out/opt/Vibe.Kanban.AppImage "$@"
      EOF
      chmod +x $out/bin/vibe-kanban

      cat > $out/share/applications/vibe-kanban.desktop <<EOF
      [Desktop Entry]
      Name=Vibe Kanban
      Comment=Kanban board for vibe coding workflows
      Exec=$out/bin/vibe-kanban
      Icon=applications-development
      Terminal=false
      Type=Application
      Categories=Development;ProjectManagement;
      StartupWMClass=Vibe Kanban
      EOF

      runHook postInstall
    '';

    meta = with super.lib; {
      description = "Desktop Kanban board for managing vibe coding tasks";
      homepage = "https://github.com/BloopAI/vibe-kanban";
      license = licenses.asl20;
      mainProgram = "vibe-kanban";
      platforms = [ "x86_64-linux" ];
      maintainers = [ ];
    };
  };
}
