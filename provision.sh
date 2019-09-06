#!/bin/bash


# installs what's necessary :p
#
# ps.: assumes you're a regular user (not `root`).
#


set -o errexit
set -o nounset
set -o pipefail


main () {
        setup_bashrc
        setup_gitconfig
        install_apt_deps
        install_go
        install_autojump
        setup_vim
}

install_apt_deps () {
        sudo apt update
        sudo apt install -y \
                bash-completion \
                bpfcc-tools \
                bpftrace \
                build-essential \
                clang \
                curl \
                git \
                htop \
                jq \
                libelf-dev \
                linux-headers-$(uname -r) \
                linux-tools-$(uname -r) \
                llvm \
                lsb-release \
                ltrace \
                pkg-config \
                silversearcher-ag \
                strace \
                tree \
                unzip \
                vim
}

install_go () {
        sudo chown -R $(whoami) /usr/local
        curl -SL https://dl.google.com/go/go1.13.linux-amd64.tar.gz | tar xvzf - -C /usr/local

        echo "
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
        " >> ~/.bashrc
}


setup_vim () {
        git clone https://github.com/cirocosta/dot-vim ~/.vim --recurse-submodules -j4
        ln -s $(realpath ~/.vim/.vimrc) $(realpath ~/.vimrc)

        echo "
export VISUAL=vim
export EDITOR=vim
        " >> ~/.bashrc
}


install_autojump () {
        local deb_file=/tmp/jump.deb

        curl -o $deb_file -SL https://github.com/gsamokovarov/jump/releases/download/v0.23.0/jump_0.23.0_amd64.deb
        sudo dpkg -i $deb_file
        rm $deb_file
}


setup_gitconfig () {
        cat << 'EOF' > ~/.gitconfig
[alias]
	ci = commit -s
	co = checkout
[push]
	default = simple
[trailer]
	ifexists = addIfDifferent
[user]
        name = Ciro S. Costa
        email = cscosta@pivotal.io
EOF
}


setup_bashrc () {
        cat << 'EOF' > ~/.bashrc
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
HISTSIZE=100000
HISTFILESIZE=200000


# set the prompt layout
#
PS1='\[\e[1m\] \w \$ \[\e[0m\]'


# activate bash completion
#
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi


# aliases
#
alias ls='ls --color=auto'
alias grep='grep --color=auto'


# autojump (that `j` thing)
#
eval "$(jump shell)"
EOF
}

main "$@"
