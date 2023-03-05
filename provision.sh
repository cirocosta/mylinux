#!/bin/bash

# installs what's necessary :p
#
# ps.: assumes you're a regular user (not `root`).
#

set -o errexit
set -o nounset
set -o pipefail

main() {
        setup_bashrc
        setup_gitconfig
        install_apt_deps
        install_go
        install_autojump
        setup_vim
        setup_tmux
}

install_apt_deps() {
        sudo apt update
        sudo apt install -y \
                bzip2 \
                bash-completion \
                build-essential \
                curl \
                git \
                htop \
                jq \
                linux-headers-$(uname -r) \
                linux-tools-$(uname -r) \
                lsb-release \
                pkg-config \
                python3-pip \
                silversearcher-ag \
                tmux \
                tree \
                unzip \
                vim
}

install_go() {
        sudo chown -R $(whoami) /usr/local

        curl -SL https://go.dev/dl/go1.20.1.linux-amd64.tar.gz | tar xvzf - -C /usr/local

        echo "
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
        " >>~/.bashrc
}

setup_vim() {
        git clone --recursive https://github.com/cirocosta/dot-vim ~/.vim
        ln -s $(realpath ~/.vim/.vimrc) $(realpath ~/.vimrc)

        echo "
export VISUAL=vim
export EDITOR=vim
        " >>~/.bashrc
}

install_autojump() {
        local deb_file=/tmp/jump.deb

        curl -o $deb_file -SL https://github.com/gsamokovarov/jump/releases/download/v0.40.0/jump_0.40.0_amd64.deb
        sudo dpkg -i $deb_file
        rm $deb_file
}

setup_gitconfig() {
        cat <<'EOF' >~/.gitconfig
[alias]
        ci = commit -s
[push]
	default = simple
[trailer]
	ifexists = addIfDifferent
EOF
}

setup_tmux() {
        cat <<'EOF' >~/.tmux.conf
set-window-option -g mode-keys vi
set -g prefix C-a
set -g history-limit 10000
bind-key -T copy-mode-vi 'v' send -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'
set -g status-style 'bg=colour75,fg=black'
set -g status-right ''
EOF
}

setup_bashrc() {
        cat <<'EOF' >~/.bashrc
# if not running interactively, don't do anything
#
[ -z "$PS1" ] && return


# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
#
shopt -s checkwinsize


# improve the history
#
shopt -s histappend
HISTCONTROL=ignoredups:ignorespace
HISTSIZE=5000000
HISTFILESIZE=2000000


# set the prompt layout
#
PS1='\[\e[1m\] \W \$ \[\e[0m\]'



# activate bash completion
#
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi


# aliases
#
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias k='kubectl'
# complete -F __start_kubectl k


# autojump (that `j` thing)
#
eval "$(jump shell)"
EOF
}

main "$@"
