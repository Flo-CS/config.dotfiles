# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export DOTS_DIR=$HOME/.dotfiles
export DOTS_ID=florian.laptop
export DOTS_THEME_NAME=rose-pine
export DOTS_WALLPAPER_FILE=mountain.jpg
# For example: "v0.50.0". Can be empty if version should not be fixed.
export DOTS_HYPRLAND_PLUGINS_VERSION=""

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

source ~/.dotfiles/config/default/.bashrc

source /usr/share/nvm/init-nvm.sh

. "$HOME/.cargo/env"

. "$HOME/.atuin/bin/env"
[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash)"
