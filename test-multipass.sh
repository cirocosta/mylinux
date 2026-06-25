#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

default_image() {
    if [ -r /etc/os-release ]; then
        . /etc/os-release
        if [ "${ID:-}" = "ubuntu" ] && [ -n "${VERSION_ID:-}" ]; then
            printf '%s\n' "$VERSION_ID"
            return
        fi
    fi

    printf '24.04\n'
}

readonly VM_NAME="${VM_NAME:-mylinux-provision-test}"
readonly IMAGE="${IMAGE:-$(default_image)}"
readonly CPUS="${CPUS:-2}"
readonly MEMORY="${MEMORY:-4G}"
readonly DISK="${DISK:-20G}"
readonly KEEP_VM="${KEEP_VM:-0}"

main() {
    local script_dir

    require_cmd multipass

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    trap cleanup EXIT

    if multipass info "$VM_NAME" >/dev/null 2>&1; then
        log "deleting existing vm: ${VM_NAME}"
        multipass delete "$VM_NAME" --purge
    fi

    log "launching ${IMAGE} vm: ${VM_NAME}"
    multipass launch "$IMAGE" \
        --name "$VM_NAME" \
        --cpus "$CPUS" \
        --memory "$MEMORY" \
        --disk "$DISK"

    log "copying provision.sh"
    multipass transfer "${script_dir}/provision.sh" "${VM_NAME}:/home/ubuntu/provision.sh"

    multipass exec "$VM_NAME" -- chmod +x /home/ubuntu/provision.sh

    log "running provision.sh gh"
    multipass exec "$VM_NAME" -- /home/ubuntu/provision.sh gh
    multipass exec "$VM_NAME" -- bash -lc 'gh --version'

    log "running provision.sh"
    multipass exec "$VM_NAME" -- /home/ubuntu/provision.sh

    log "checking provision.sh go idempotence"
    multipass exec "$VM_NAME" -- bash -lc 'PATH=/usr/bin:/bin /home/ubuntu/provision.sh go | grep -Fxq "==> go 1.26.4 already installed"'

    log "running provision.sh again"
    multipass exec "$VM_NAME" -- /home/ubuntu/provision.sh

    log "checking installed tools"
    multipass exec "$VM_NAME" -- bash -lc 'gh --version'
    multipass exec "$VM_NAME" -- bash -ic 'go version'
    multipass exec "$VM_NAME" -- bash -lc 'node --version | grep -Fxq v24.18.0'
    multipass exec "$VM_NAME" -- bash -lc 'npm --version'
    multipass exec "$VM_NAME" -- bash -lc 'npx --version'
    multipass exec "$VM_NAME" -- bash -lc 'corepack --version'
    multipass exec "$VM_NAME" -- bash -lc 'shfmt --version | grep -Fxq v3.13.1'
    multipass exec "$VM_NAME" -- bash -lc 'golangci-lint version | grep -Fq "version 2.12.2"'
    multipass exec "$VM_NAME" -- bash -lc 'sudo systemctl is-active --quiet docker.service'
    multipass exec "$VM_NAME" -- bash -lc "sudo docker version --format '{{.Server.Version}}'"
    multipass exec "$VM_NAME" -- bash -lc 'docker compose version'
    multipass exec "$VM_NAME" -- bash -lc 'docker buildx version'
    multipass exec "$VM_NAME" -- bash -lc 'containerd --version'
    multipass exec "$VM_NAME" -- bash -lc 'jump --version'
    multipass exec "$VM_NAME" -- bash -lc 'sudo bpftrace --version'
    multipass exec "$VM_NAME" -- bash -lc 'test ! -e /usr/local/bin/bpftrace'
    multipass exec "$VM_NAME" -- bash -lc 'tmux -V'
    multipass exec "$VM_NAME" -- bash -lc 'vim --version | head -n 1'
    multipass exec "$VM_NAME" -- bash -lc 'grep -Fxq "# Managed by mylinux provision.sh." "$HOME/.bashrc"'
    multipass exec "$VM_NAME" -- bash -lc 'grep -Fxq "alias k='\''kubectl'\''" "$HOME/.bashrc"'
    multipass exec "$VM_NAME" -- bash -lc 'test ! -e "$HOME/.config/mylinux/bashrc"'
    multipass exec "$VM_NAME" -- bash -lc 'test -f "$HOME/.config/mylinux/gitconfig"'
    multipass exec "$VM_NAME" -- bash -lc 'test -f "$HOME/.config/mylinux/tmux.conf"'
    multipass exec "$VM_NAME" -- bash -lc 'grep -Fq "split-window -v -c \"#{pane_current_path}\"" "$HOME/.config/mylinux/tmux.conf"'
    multipass exec "$VM_NAME" -- bash -lc 'grep -Fq "split-window -h -c \"#{pane_current_path}\"" "$HOME/.config/mylinux/tmux.conf"'
}

cleanup() {
    if [ "$KEEP_VM" = "1" ]; then
        log "keeping vm: ${VM_NAME}"
        return
    fi

    multipass delete "$VM_NAME" --purge >/dev/null 2>&1 || true
}

log() {
    printf '==> %s\n' "$*"
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'error: missing required command: %s\n' "$1" >&2
        exit 1
    }
}

main "$@"
