# Generated for envman. Do not edit.
test -s "$HOME/.config/envman/load.sh" && . "$HOME/.config/envman/load.sh"
test -s "$HOME/.config/envman/functions.sh" && . "$HOME/.config/envman/functions.sh"

. "$HOME/.cargo/env"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

if test -e ~/.local/opt/brew/opt/chruby/share/chruby/chruby.sh; then
    # shellcheck disable=SC1090
    . ~/.local/opt/brew/opt/chruby/share/chruby/chruby.sh
fi

# for when logging in to default shell (zsh) via ssh
screen -xRS awesome -s fish
