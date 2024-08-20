# use vim as the visual editor
export VISUAL=vim
export EDITOR=$VISUAL
export LC_ALL=$LANG

# do not overide here, use zshenv.local instead
export CC_GOOD_COMMAND="🤭"
export CC_BAD_COMMAND="🧐"

#Use fd with fzf
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'

# ensure dotfiles bin directory is loaded first
export PATH="$HOME/.bin:/usr/local/sbin:$PATH"

# Local config
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
