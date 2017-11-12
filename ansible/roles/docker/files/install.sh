#!/bin/bash

set -o errexit

main() {
  install_docker
}

install_docker() {
  echo "INFO:
  Installing Docker from release-candidate channel
  "

  curl -fsSL https://test.docker.com/ | sh
  usermod -aG docker ubuntu
}

main
