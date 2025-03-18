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
[[ -f ~/.secrets.zsh ]] && source  ~/.secrets.zsh || echo "Error: Failed to load secrets"

PATH=~/.console-ninja/.bin:$PATH

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
    echo "Direnv for $lang has been set up. Happy coding!"
  else
    echo "No development shell found for $lang"
  fi
}


