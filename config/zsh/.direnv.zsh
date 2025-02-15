
# Direnv & Shell helpers 
function _ncs_setup() {
cp ~/nixos/shells/$1/{flake.nix,flake.lock} ./
_git_init_flake
_direnv_init
}

function _git_init_flake() {
if [ ! -d .git ]; then
    git init
fi
git add flake.nix flake.lock
}

function _direnv_init() {
echo 'use flake' > .envrc
direnv allow
}