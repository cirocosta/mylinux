#!/bin/bash
set -o errexit
set -o nounset

main () {
        apt_base_deps
        install_go
        setup_vim
}

install_go () {
        curl -SL https://dl.google.com/go/go1.13.linux-amd64.tar.gz | tar xvzf - -C /usr/local

        echo "
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
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

apt_base_deps () {
        apt update
        apt install -y \
                bash-completion \
                bpfcc-tools \
                bpftrace \
                build-essential \
                curl \
                git \
                htop \
                jq \
                linux-headers-$(uname -r) \
                lsb-release \
                ltrace \
                pkg-config \
                silversearcher-ag \
                strace \
                tree \
                unzip \
                vim
}

main "$@"
