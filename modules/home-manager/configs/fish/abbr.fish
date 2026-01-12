# Fish abbreviations - converted from zsh aliases

# ============================================================================
# STANDARD ALIASES
# ============================================================================

abbr -a pcuptime "uptime | awk '{print \$3}' | sed 's/,//'"
abbr -a cat "bat"
abbr -a cc "wl-copy --primary --trim-newline"
abbr -a diff "batdiff"
abbr -a man "batman"
abbr -a ll "eza -l"
abbr -a ls "eza"
abbr -a update "~/nixos/update.sh"

# ============================================================================
# DEV ENVIRONMENT SETUP (ncs-*)
# ============================================================================

abbr -a ncs-csharp "_ncs_setup csharp"
abbr -a ncs-go "_ncs_setup go"
abbr -a ncs-java "_ncs_setup java"
abbr -a ncs-maui "_ncs_setup maui"
abbr -a ncs-php "_ncs_setup php"
abbr -a ncs-nodejs "_ncs_setup node"
abbr -a ncs-python3 "_ncs_setup python3"
abbr -a ncs-react-native "_ncs_setup react-native"
abbr -a ncs-rust "_ncs_setup rust"
abbr -a ncs-tauri "_ncs_setup tauri"
abbr -a ncs-unity "_ncs_setup unity"

# ============================================================================
# NIX DEVELOP SHORTCUTS (nas-*)
# ============================================================================

abbr -a nas-c "nix develop ~/nixos/shells/c"
abbr -a nas-csharp "nix develop ~/nixos/shells/csharp"
abbr -a nas-go "nix develop ~/nixos/shells/go"
abbr -a nas-java "nix develop ~/nixos/shells/java"
abbr -a nas-maui "nix develop ~/nixos/shells/maui"
abbr -a nas-php "nix develop ~/nixos/shells/php"
abbr -a nas-nodejs "nix develop ~/nixos/shells/node"
abbr -a nas-python3 "nix develop ~/nixos/shells/python3"
abbr -a nas-react-native "nix develop ~/nixos/shells/react-native"
abbr -a nas-rust "nix develop ~/nixos/shells/rust"
abbr -a nas-tauri "nix develop ~/nixos/shells/tauri"
abbr -a nas-unity "nix develop ~/nixos/shells/unity"
