#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly VM_NAME="${VM_NAME:-mylinux-provision-test}"
readonly IMAGE="${IMAGE:-24.04}"
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

    log "running provision.sh"
    multipass exec "$VM_NAME" -- chmod +x /home/ubuntu/provision.sh
    multipass exec "$VM_NAME" -- /home/ubuntu/provision.sh

    log "running provision.sh again"
    multipass exec "$VM_NAME" -- /home/ubuntu/provision.sh

    log "checking installed tools"
    multipass exec "$VM_NAME" -- bash -lc 'go version'
    multipass exec "$VM_NAME" -- bash -lc 'jump --version'
    multipass exec "$VM_NAME" -- bash -lc 'bpftrace --version'
    multipass exec "$VM_NAME" -- bash -lc 'tmux -V'
    multipass exec "$VM_NAME" -- bash -lc 'vim --version | head -n 1'
    multipass exec "$VM_NAME" -- bash -lc 'test -f "$HOME/.config/mylinux/bashrc"'
    multipass exec "$VM_NAME" -- bash -lc 'test -f "$HOME/.config/mylinux/gitconfig"'
    multipass exec "$VM_NAME" -- bash -lc 'test -f "$HOME/.config/mylinux/tmux.conf"'
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
