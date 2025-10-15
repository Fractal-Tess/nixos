if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec Hyprland
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

setopt autocd extendedglob notify
bindkey -e
# End of lines configured by zsh-newuser-install

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh || echo "Error: Failed to load p10k config"

# Load custom secrets
[[ -f ~/.secrets.zsh ]] && source ~/.secrets.zsh

PATH=/home/fractal-tess/nixos/scripts:$PATH

# pnpm
export PNPM_HOME="/home/fractal-tess/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Function to set up and copy Nix development shell files
function _ncs_setup() {
  local lang="$1"
  if [ -d "$HOME/nixos/shells/$lang" ]; then
    cp -r "$HOME/nixos/shells/$lang/"* "$PWD"
    echo "use flake" > ".envrc"
    if [ -d .git ]; then
      git add flake.lock flake.nix .envrc
      direnv allow
    fi
    echo "Direnv for $lang has been set up. Happy coding!"
  else
    echo "No development shell found for $lang"
  fi
}


if [[ -n $CURSOR_TRACE_ID ]]; then
  PROMPT_EOL_MARK=""
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
  precmd() { print -Pn "\e]133;D;%?\a" }
  preexec() { print -Pn "\e]133;C;\a" }
fi

#Aliases
alias p10k-down='prompt_powerlevel9k_teardown'
alias p10k-up='prompt_powerlevel9k_setup'
alias ca='cursor-agent'
alias zai='~/nixos/scripts/claude-code/z-ai.sh'

# ppwn function that changes directory after running the script
ppwn() {
    local executable="$1"
    if [ $# -lt 1 ]; then
        echo "Usage: ppwn <executable>"
        return 1
    fi

    # Check if the executable exists
    if [ ! -f "$executable" ]; then
        echo "Error: File '$executable' does not exist"
        return 1
    fi

    # Get the executable name
    local executable_name=$(basename "$executable")

    # Prompt user for folder name, default to executable name
    read -p "Enter folder name (default: $executable_name): " folder_name

    # Use default if user didn't enter anything
    if [ -z "$folder_name" ]; then
        folder_name="$executable_name"
    fi

    # Create the target directory
    local target_dir="$HOME/dev/ctfs/ppwn/$folder_name"
    mkdir -p "$target_dir"

    # Move the executable to the target directory
    mv "$executable" "$target_dir/"

    # Make it executable
    chmod +x "$target_dir/$executable_name"

    echo "Successfully moved '$executable' to '$target_dir/$executable_name'"
    echo "You can now run it with: $target_dir/$executable_name"

    # Open cutter with the moved binary in background
    echo "Opening cutter with the binary..."
    cutter "$target_dir/$executable_name" >/dev/null 2>&1 &

    echo "Cutter is now running in the background with the binary loaded."

    # Change to the target directory
    cd "$target_dir"

    echo "Changed directory to: $target_dir"
}

#End
if [[ -n $CURSOR_TRACE_ID ]]; then
  p10k-down
fi
