{ pkgs, username, ... }:

let
  azerothSurvivors = pkgs.writeShellApplication {
    name = "azeroth-survivors";
    runtimeInputs = [ pkgs.steam-run ];
    text = ''
      GAME_ROOT="/home/${username}/Games/azeroth-survivors"
      GAME_EXE="$GAME_ROOT/windows/AzerothSurvivors/AzerothSurvivors.exe"
      export STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/${username}/.local/share/Steam"
      PROTON=""
      for version in "Proton - Experimental" "Proton Hotfix"; do
        candidate="$STEAM_COMPAT_CLIENT_INSTALL_PATH/steamapps/common/$version/proton"
        if [[ -f "$candidate" ]]; then
          PROTON="$candidate"
          break
        fi
      done

      if [[ ! -f "$GAME_EXE" || ! -f "$PROTON" ]]; then
        echo "Azeroth Survivors requires the installed Windows game and Steam's Proton Experimental or Proton Hotfix." >&2
        exit 1
      fi

      mkdir -p "$GAME_ROOT/proton-prefix"
      export STEAM_COMPAT_DATA_PATH="$GAME_ROOT/proton-prefix"
      export SteamAppId=0
      export SteamGameId=0
      export WGPU_BACKEND=vulkan
      export PROTON_LOG=1
      export PROTON_LOG_DIR="$GAME_ROOT"
      cd "$(dirname "$GAME_EXE")"
      exec steam-run "$PROTON" run "$GAME_EXE" "$@"
    '';
  };
in
{
  home.packages = [ azerothSurvivors ];
  xdg.desktopEntries.azeroth-survivors-native = {
    name = "Azeroth Survivors (Proton)";
    comment = "Official Windows game through Proton with Vulkan";
    exec = "${azerothSurvivors}/bin/azeroth-survivors";
    icon = "applications-games";
    terminal = false;
    categories = [ "Game" ];
  };

}
