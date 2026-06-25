#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly GO_VERSION="1.26.4"
readonly GO_SHA256_AMD64="1153d3d50e0ac764b447adfe05c2bcf08e889d42a02e0fe0259bd47f6733ad7f"
readonly GO_SHA256_ARM64="ef758ae7c6cf9267c9c0ef080b8965f453d89ab2d25d9eb22de4405925238768"

readonly NODE_VERSION="24.18.0"
readonly NODE_SHA256_X64="783130984963db7ba9cbd01089eaf2c2efb055c7c1693c943174b967b3050cb8"
readonly NODE_SHA256_ARM64="6b4484c2190274175df9aa8f28e2d758a819cb1c1fe6ab481e2f95b463ab8508"

readonly SHFMT_VERSION="3.13.1"
readonly SHFMT_SHA256_AMD64="fb096c5d1ac6beabbdbaa2874d025badb03ee07929f0c9ff67563ce8c75398b1"
readonly SHFMT_SHA256_ARM64="32d92acaa5cd8abb29fc49dac123dc412442d5713967819d8af2c29f1b3857c7"

readonly GOLANGCI_LINT_VERSION="2.12.2"
readonly GOLANGCI_LINT_SHA256_AMD64="8df580d2670fed8fa984aac0507099af8df275e665215f5c7a2ae3943893a553"
readonly GOLANGCI_LINT_SHA256_ARM64="44cd40a8c76c86755375adfeea52cfd3533cb43d7bd647771e0ae065e166df3a"

readonly UV_VERSION="0.11.24"
readonly UV_SHA256_X86_64="5ce1ad074a78f96c5c8122088bb85a12eb282195bc1453151a48762e4fc31fed"
readonly UV_SHA256_AARCH64="e22c66d36a0098b17cff80a8647e0b8c58202af899d4e9eb820fc7ad126435a1"

readonly RUFF_VERSION="0.15.20"
readonly RUFF_SHA256_X86_64="df8e74862d4cd4fdac11faf3048789896ff9898a0cacb98497df20d0a1cc7bb4"
readonly RUFF_SHA256_AARCH64="f915de3ab6d31a49f4c57b1f97129f359f9348c162ea03acfa07011ba79e1197"

readonly JUMP_VERSION="0.67.0"

readonly BPFTRACE_APPIMAGE_SHA256_AMD64="17ded991241f8c6c56bf907aab948ef172404ed2a5ea2f0e11f73a7652f3dcc0"

readonly GITHUB_CLI_KEYRING_SHA256="6084d5d7bd8e288441e0e94fc6275570895da18e6751f70f057485dc2d1a811b"
readonly GITHUB_CLI_KEYRING_URL="https://cli.github.com/packages/githubcli-archive-keyring.gpg"

readonly DOCKER_DOWNLOAD_URL="https://download.docker.com"

readonly MYLINUX_CONFIG_DIR="${HOME}/.config/mylinux"

main() {
    if [ "$#" -gt 1 ]; then
        usage >&2
        exit 2
    fi

    case "${1:-all}" in
        -h | --help | help)
            usage
            return
            ;;
    esac

    require_regular_user
    require_cmd sudo
    require_cmd apt

    run_target "${1:-all}"
}

usage() {
    cat <<'EOF'
usage: provision.sh [all|apt|gh|go|nodejs|shfmt|golangci-lint|uv|ruff|docker|jump|bpftrace|bash|git|vim|tmux]

With no argument, runs the full provisioning flow.
EOF
}

run_target() {
    case "$1" in
        all)
            provision_all
            ;;
        apt)
            install_apt_deps
            ;;
        gh | github-cli)
            install_github_cli
            ;;
        go)
            install_go
            ;;
        node | nodejs)
            install_nodejs
            ;;
        shfmt)
            install_shfmt
            ;;
        golangci | golangci-lint)
            install_golangci_lint
            ;;
        uv)
            install_uv
            ;;
        ruff)
            install_ruff
            ;;
        docker)
            install_docker
            ;;
        jump)
            install_go
            install_jump
            ;;
        bpftrace)
            install_bpftrace
            ;;
        bash | bashrc)
            setup_bashrc
            ;;
        git | gitconfig)
            setup_gitconfig
            ;;
        vim)
            setup_vim
            ;;
        tmux)
            setup_tmux
            ;;
        *)
            printf 'error: unknown target: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
}

provision_all() {
    install_apt_deps
    install_github_cli
    install_go
    install_nodejs
    install_shfmt
    install_golangci_lint
    install_uv
    install_ruff
    install_docker
    install_jump
    install_bpftrace
    setup_bashrc
    setup_gitconfig
    setup_vim
    setup_tmux
}

log() {
    printf '==> %s\n' "$*"
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

require_regular_user() {
    if [ "${EUID}" -eq 0 ]; then
        die "run as a regular user with sudo access, not root"
    fi
}

ensure_apt_packages() {
    local missing=()
    local package

    for package in "$@"; do
        if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -Fq 'install ok installed'; then
            missing+=("$package")
        fi
    done

    if [ "${#missing[@]}" -eq 0 ]; then
        return
    fi

    log "installing apt prerequisites: ${missing[*]}"
    sudo apt update
    sudo apt install -y "${missing[@]}"
}

install_apt_deps() {
    local packages=(
        bash-completion
        build-essential
        bzip2
        ca-certificates
        curl
        git
        htop
        jq
        linux-tools-common
        lsb-release
        pkg-config
        python3-pip
        silversearcher-ag
        tmux
        tree
        unzip
        vim
        xclip
    )

    log "installing apt packages"
    sudo apt update
    sudo apt install -y "${packages[@]}"

    install_apt_if_available "linux-headers-$(uname -r)"
    install_apt_if_available "linux-tools-$(uname -r)"
}

install_apt_if_available() {
    local package="$1"

    if apt-cache show "$package" >/dev/null 2>&1; then
        sudo apt install -y "$package"
    else
        log "apt package unavailable: $package"
    fi
}

install_github_cli() {
    local keyring="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
    local source_file="/etc/apt/sources.list.d/github-cli.list"
    local source_line
    local tmp

    source_line="deb [arch=$(dpkg --print-architecture) signed-by=${keyring}] https://cli.github.com/packages stable main"

    log "installing github cli"
    ensure_apt_packages ca-certificates curl

    tmp="$(mktemp)"
    curl -fsSL -o "$tmp" "$GITHUB_CLI_KEYRING_URL"
    printf '%s  %s\n' "$GITHUB_CLI_KEYRING_SHA256" "$tmp" | sha256sum -c -

    sudo install -d -m 0755 /etc/apt/keyrings /etc/apt/sources.list.d
    sudo install -m 0644 "$tmp" "$keyring"
    rm -f "$tmp"

    printf '%s\n' "$source_line" | sudo tee "$source_file" >/dev/null

    sudo apt update
    sudo apt install -y gh
}

install_go() {
    local arch
    local filename
    local sha256
    local tarball
    local tmp_dir
    local url

    if [ -x /usr/local/go/bin/go ] && /usr/local/go/bin/go version | grep -Fq "go${GO_VERSION} "; then
        log "go ${GO_VERSION} already installed"
        return
    fi

    if command -v go >/dev/null 2>&1 && go version | grep -Fq "go${GO_VERSION} "; then
        log "go ${GO_VERSION} already installed"
        return
    fi

    arch="$(go_arch)"
    filename="go${GO_VERSION}.linux-${arch}.tar.gz"
    sha256="$(go_sha256 "$arch")"
    url="https://go.dev/dl/${filename}"

    log "installing go ${GO_VERSION}"
    ensure_apt_packages ca-certificates curl

    tmp_dir="$(mktemp -d)"
    tarball="${tmp_dir}/${filename}"

    curl -fsSL -o "$tarball" "$url"
    printf '%s  %s\n' "$sha256" "$tarball" | sha256sum -c -

    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$tarball"

    rm -rf "$tmp_dir"
}

go_arch() {
    case "$(uname -m)" in
        x86_64 | amd64)
            printf 'amd64\n'
            ;;
        aarch64 | arm64)
            printf 'arm64\n'
            ;;
        *)
            die "unsupported go architecture: $(uname -m)"
            ;;
    esac
}

go_sha256() {
    case "$1" in
        amd64)
            printf '%s\n' "$GO_SHA256_AMD64"
            ;;
        arm64)
            printf '%s\n' "$GO_SHA256_ARM64"
            ;;
        *)
            die "unsupported go checksum architecture: $1"
            ;;
    esac
}

install_nodejs() {
    local arch
    local filename
    local install_dir="/usr/local/nodejs"
    local sha256
    local tarball
    local tmp_dir
    local url

    if [ -x "${install_dir}/bin/node" ] && [ "$("${install_dir}/bin/node" --version)" = "v${NODE_VERSION}" ]; then
        log "nodejs ${NODE_VERSION} already installed"
        return
    fi

    if command -v node >/dev/null 2>&1 && [ "$(node --version)" = "v${NODE_VERSION}" ]; then
        log "nodejs ${NODE_VERSION} already installed"
        return
    fi

    arch="$(node_arch)"
    filename="node-v${NODE_VERSION}-linux-${arch}.tar.gz"
    sha256="$(node_sha256 "$arch")"
    url="https://nodejs.org/dist/v${NODE_VERSION}/${filename}"

    log "installing nodejs ${NODE_VERSION}"
    ensure_apt_packages ca-certificates curl

    tmp_dir="$(mktemp -d)"
    tarball="${tmp_dir}/${filename}"

    curl -fsSL -o "$tarball" "$url"
    printf '%s  %s\n' "$sha256" "$tarball" | sha256sum -c -

    sudo rm -rf "$install_dir"
    sudo install -d -m 0755 "$install_dir"
    sudo tar -C "$install_dir" --strip-components=1 -xzf "$tarball"
    sudo ln -sfn "${install_dir}/bin/node" /usr/local/bin/node
    sudo ln -sfn "${install_dir}/bin/npm" /usr/local/bin/npm
    sudo ln -sfn "${install_dir}/bin/npx" /usr/local/bin/npx
    sudo ln -sfn "${install_dir}/bin/corepack" /usr/local/bin/corepack

    rm -rf "$tmp_dir"
}

node_arch() {
    case "$(uname -m)" in
        x86_64 | amd64)
            printf 'x64\n'
            ;;
        aarch64 | arm64)
            printf 'arm64\n'
            ;;
        *)
            die "unsupported nodejs architecture: $(uname -m)"
            ;;
    esac
}

node_sha256() {
    case "$1" in
        x64)
            printf '%s\n' "$NODE_SHA256_X64"
            ;;
        arm64)
            printf '%s\n' "$NODE_SHA256_ARM64"
            ;;
        *)
            die "unsupported nodejs checksum architecture: $1"
            ;;
    esac
}

install_shfmt() {
    local arch
    local binary
    local sha256
    local tmp
    local url

    if command -v shfmt >/dev/null 2>&1 && [ "$(shfmt --version)" = "v${SHFMT_VERSION}" ]; then
        log "shfmt ${SHFMT_VERSION} already installed"
        return
    fi

    arch="$(go_arch)"
    binary="shfmt_v${SHFMT_VERSION}_linux_${arch}"
    sha256="$(shfmt_sha256 "$arch")"
    url="https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/${binary}"

    log "installing shfmt ${SHFMT_VERSION}"
    ensure_apt_packages ca-certificates curl

    tmp="$(mktemp)"
    curl -fsSL -o "$tmp" "$url"
    printf '%s  %s\n' "$sha256" "$tmp" | sha256sum -c -

    sudo install -D -m 0755 "$tmp" /usr/local/bin/shfmt
    rm -f "$tmp"
}

shfmt_sha256() {
    case "$1" in
        amd64)
            printf '%s\n' "$SHFMT_SHA256_AMD64"
            ;;
        arm64)
            printf '%s\n' "$SHFMT_SHA256_ARM64"
            ;;
        *)
            die "unsupported shfmt checksum architecture: $1"
            ;;
    esac
}

install_golangci_lint() {
    local arch
    local dirname
    local filename
    local sha256
    local tarball
    local tmp_dir
    local url

    if command -v golangci-lint >/dev/null 2>&1 &&
        golangci-lint version 2>/dev/null | grep -Fq "version ${GOLANGCI_LINT_VERSION}"; then
        log "golangci-lint ${GOLANGCI_LINT_VERSION} already installed"
        return
    fi

    arch="$(go_arch)"
    dirname="golangci-lint-${GOLANGCI_LINT_VERSION}-linux-${arch}"
    filename="${dirname}.tar.gz"
    sha256="$(golangci_lint_sha256 "$arch")"
    url="https://github.com/golangci/golangci-lint/releases/download/v${GOLANGCI_LINT_VERSION}/${filename}"

    log "installing golangci-lint ${GOLANGCI_LINT_VERSION}"
    ensure_apt_packages ca-certificates curl

    tmp_dir="$(mktemp -d)"
    tarball="${tmp_dir}/${filename}"

    curl -fsSL -o "$tarball" "$url"
    printf '%s  %s\n' "$sha256" "$tarball" | sha256sum -c -
    tar -C "$tmp_dir" -xzf "$tarball"

    sudo install -D -m 0755 "${tmp_dir}/${dirname}/golangci-lint" /usr/local/bin/golangci-lint
    rm -rf "$tmp_dir"
}

golangci_lint_sha256() {
    case "$1" in
        amd64)
            printf '%s\n' "$GOLANGCI_LINT_SHA256_AMD64"
            ;;
        arm64)
            printf '%s\n' "$GOLANGCI_LINT_SHA256_ARM64"
            ;;
        *)
            die "unsupported golangci-lint checksum architecture: $1"
            ;;
    esac
}

install_uv() {
    local arch
    local dirname
    local filename
    local sha256
    local tarball
    local tmp_dir
    local url

    if command -v uv >/dev/null 2>&1 &&
        command -v uvx >/dev/null 2>&1 &&
        uv --version | grep -Fq "uv ${UV_VERSION}" &&
        uvx --version | grep -Fq "uvx ${UV_VERSION}"; then
        log "uv ${UV_VERSION} already installed"
        return
    fi

    arch="$(rust_linux_arch)"
    dirname="uv-${arch}"
    filename="${dirname}.tar.gz"
    sha256="$(uv_sha256 "$arch")"
    url="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${filename}"

    log "installing uv ${UV_VERSION}"
    ensure_apt_packages ca-certificates curl

    tmp_dir="$(mktemp -d)"
    tarball="${tmp_dir}/${filename}"

    curl -fsSL -o "$tarball" "$url"
    printf '%s  %s\n' "$sha256" "$tarball" | sha256sum -c -
    tar -C "$tmp_dir" -xzf "$tarball"

    sudo install -D -m 0755 "${tmp_dir}/${dirname}/uv" /usr/local/bin/uv
    sudo install -D -m 0755 "${tmp_dir}/${dirname}/uvx" /usr/local/bin/uvx
    rm -rf "$tmp_dir"
}

uv_sha256() {
    case "$1" in
        x86_64-unknown-linux-gnu)
            printf '%s\n' "$UV_SHA256_X86_64"
            ;;
        aarch64-unknown-linux-gnu)
            printf '%s\n' "$UV_SHA256_AARCH64"
            ;;
        *)
            die "unsupported uv checksum architecture: $1"
            ;;
    esac
}

install_ruff() {
    local arch
    local dirname
    local filename
    local sha256
    local tarball
    local tmp_dir
    local url

    if command -v ruff >/dev/null 2>&1 && [ "$(ruff --version)" = "ruff ${RUFF_VERSION}" ]; then
        log "ruff ${RUFF_VERSION} already installed"
        return
    fi

    arch="$(rust_linux_arch)"
    dirname="ruff-${arch}"
    filename="${dirname}.tar.gz"
    sha256="$(ruff_sha256 "$arch")"
    url="https://github.com/astral-sh/ruff/releases/download/${RUFF_VERSION}/${filename}"

    log "installing ruff ${RUFF_VERSION}"
    ensure_apt_packages ca-certificates curl

    tmp_dir="$(mktemp -d)"
    tarball="${tmp_dir}/${filename}"

    curl -fsSL -o "$tarball" "$url"
    printf '%s  %s\n' "$sha256" "$tarball" | sha256sum -c -
    tar -C "$tmp_dir" -xzf "$tarball"

    sudo install -D -m 0755 "${tmp_dir}/${dirname}/ruff" /usr/local/bin/ruff
    rm -rf "$tmp_dir"
}

ruff_sha256() {
    case "$1" in
        x86_64-unknown-linux-gnu)
            printf '%s\n' "$RUFF_SHA256_X86_64"
            ;;
        aarch64-unknown-linux-gnu)
            printf '%s\n' "$RUFF_SHA256_AARCH64"
            ;;
        *)
            die "unsupported ruff checksum architecture: $1"
            ;;
    esac
}

rust_linux_arch() {
    case "$(uname -m)" in
        x86_64 | amd64)
            printf 'x86_64-unknown-linux-gnu\n'
            ;;
        aarch64 | arm64)
            printf 'aarch64-unknown-linux-gnu\n'
            ;;
        *)
            die "unsupported rust linux architecture: $(uname -m)"
            ;;
    esac
}

install_docker() {
    local packages=(
        containerd.io
        docker-buildx-plugin
        docker-ce
        docker-ce-cli
        docker-ce-rootless-extras
        docker-compose-plugin
        docker-model-plugin
    )

    log "installing docker"
    setup_docker_apt_repo

    sudo apt update
    sudo apt install -y "${packages[@]}"

    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl enable --now docker.service
    fi
}

setup_docker_apt_repo() {
    local codename
    local distribution
    local keyring="/etc/apt/keyrings/docker.asc"
    local source_file="/etc/apt/sources.list.d/docker.list"
    local source_line
    local tmp

    distribution="$(docker_distribution)"
    codename="$(docker_codename)"
    source_line="deb [arch=$(dpkg --print-architecture) signed-by=${keyring}] ${DOCKER_DOWNLOAD_URL}/linux/${distribution} ${codename} stable"

    ensure_apt_packages ca-certificates curl

    tmp="$(mktemp)"
    curl -fsSL -o "$tmp" "${DOCKER_DOWNLOAD_URL}/linux/${distribution}/gpg"

    sudo install -d -m 0755 /etc/apt/keyrings /etc/apt/sources.list.d
    sudo install -m 0644 "$tmp" "$keyring"
    rm -f "$tmp"

    printf '%s\n' "$source_line" | sudo tee "$source_file" >/dev/null
}

docker_distribution() {
    local id

    if [ ! -r /etc/os-release ]; then
        die "cannot detect docker distribution: missing /etc/os-release"
    fi

    id="$(. /etc/os-release && printf '%s\n' "${ID:-}")"
    case "$id" in
        debian | ubuntu)
            printf '%s\n' "$id"
            ;;
        *)
            die "unsupported docker distribution: $id"
            ;;
    esac
}

docker_codename() {
    local codename

    codename="$(. /etc/os-release && printf '%s\n' "${VERSION_CODENAME:-}")"
    if [ -n "$codename" ]; then
        printf '%s\n' "$codename"
        return
    fi

    if command -v lsb_release >/dev/null 2>&1; then
        lsb_release --codename | cut -f2
        return
    fi

    die "cannot detect docker distribution codename"
}

install_jump() {
    if command -v jump >/dev/null 2>&1 && [ "$(jump --version 2>/dev/null)" = "$JUMP_VERSION" ]; then
        log "jump ${JUMP_VERSION} already installed"
        return
    fi

    log "installing jump ${JUMP_VERSION}"
    sudo env "PATH=/usr/local/go/bin:${PATH}" GOBIN=/usr/local/bin \
        go install "github.com/gsamokovarov/jump@v${JUMP_VERSION}"
}

install_bpftrace() {
    local installed_binary="/usr/local/bin/bpftrace"

    log "installing bpftrace"
    sudo apt update
    sudo apt install -y bpftrace

    if [ -f "$installed_binary" ] &&
        printf '%s  %s\n' "$BPFTRACE_APPIMAGE_SHA256_AMD64" "$installed_binary" | sha256sum -c - >/dev/null 2>&1; then
        log "removing previously provisioned bpftrace AppImage"
        sudo rm -f "$installed_binary"
    fi
}

setup_bashrc() {
    local bashrc="${HOME}/.bashrc"

    log "configuring bash"
    write_file_if_changed "$bashrc" <<'EOF'
# Managed by mylinux provision.sh.
[ -z "${PS1:-}" ] && return

shopt -s checkwinsize
shopt -s histappend

HISTCONTROL=ignoredups:ignorespace
HISTSIZE=5000000
HISTFILESIZE=2000000

PS1='\[\e[1m\] \W \$ \[\e[0m\]'

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias k='kubectl'

export GOPATH="$HOME/go"
case ":$PATH:" in
    *:/usr/local/go/bin:*) ;;
    *) export PATH="/usr/local/go/bin:$PATH" ;;
esac
case ":$PATH:" in
    *:"$HOME/go/bin":*) ;;
    *) export PATH="$PATH:$HOME/go/bin" ;;
esac

export VISUAL=vim
export EDITOR=vim

if command -v jump >/dev/null 2>&1; then
    eval "$(jump shell)"
fi
EOF
}

setup_gitconfig() {
    local gitconfig="${MYLINUX_CONFIG_DIR}/gitconfig"

    log "configuring git"
    write_file_if_changed "$gitconfig" <<'EOF'
[alias]
    ci = commit -s -S
[push]
    default = simple
[trailer]
    ifexists = addIfDifferent
EOF

    if ! git config --global --get-all include.path | grep -Fxq "$gitconfig"; then
        git config --global --add include.path "$gitconfig"
    fi
}

setup_vim() {
    local vim_dir="${HOME}/.vim"
    local vimrc="${HOME}/.vimrc"

    log "configuring vim"
    if [ -d "${vim_dir}/.git" ]; then
        git -C "$vim_dir" pull --ff-only
        git -C "$vim_dir" submodule update --init --recursive
    elif [ -e "$vim_dir" ]; then
        log "leaving existing ${vim_dir} in place"
    else
        git clone --recursive https://github.com/cirocosta/dot-vim "$vim_dir"
    fi

    if [ -f "${vim_dir}/.vimrc" ]; then
        ensure_symlink "${vim_dir}/.vimrc" "$vimrc"
    fi
}

setup_tmux() {
    local source_line="source-file ${MYLINUX_CONFIG_DIR}/tmux.conf"
    local tmux_conf="${MYLINUX_CONFIG_DIR}/tmux.conf"

    log "configuring tmux"
    write_file_if_changed "$tmux_conf" <<'EOF'
set-window-option -g mode-keys vi
set -g prefix C-a
set -g history-limit 10000
bind-key '"' split-window -v -c "#{pane_current_path}"
bind-key '%' split-window -h -c "#{pane_current_path}"
bind-key -T copy-mode-vi 'v' send -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'
set -g status-style 'bg=colour75,fg=black'
set -g status-right ''
EOF

    ensure_line "${HOME}/.tmux.conf" "$source_line"
}

write_file_if_changed() {
    local target="$1"
    local tmp

    tmp="$(mktemp)"
    cat >"$tmp"

    if [ -f "$target" ] && cmp -s "$tmp" "$target"; then
        rm -f "$tmp"
        return
    fi

    install -D -m 0644 "$tmp" "$target"
    rm -f "$tmp"
}

ensure_line() {
    local file="$1"
    local line="$2"

    mkdir -p "$(dirname "$file")"
    touch "$file"

    if ! grep -Fxq "$line" "$file"; then
        printf '%s\n' "$line" >>"$file"
    fi
}

ensure_symlink() {
    local target="$1"
    local link="$2"

    if [ -L "$link" ] || [ ! -e "$link" ]; then
        ln -sfn "$target" "$link"
    else
        log "leaving existing ${link} in place"
    fi
}

main "$@"
