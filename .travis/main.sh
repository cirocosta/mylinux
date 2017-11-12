#!/bin/bash

set -o errexit

main() {
  setup_dependencies
  configure_local_ssh

  echo "INFO:
  Done! Finished setting up travis machine.
  "
}

configure_local_ssh() {
  echo "INFO:
  Removing need for host auth for localhost ssh.
  "

  echo "NoHostAuthenticationForLocalhost yes" |
    sudo tee \
      --append /etc/ssh/ssh_config
}

setup_dependencies() {
  echo "INFO:
  Setting up dependencies.
  "

  sudo apt update -y
  sudo apt install realpath python python-pip -y
  sudo apt install --only-upgrade docker-ce -y

  git --version
  git config --global user.name "WeDeploy CI"
  git config --global user.email "ci@wedeploy.com"

  sudo pip install docker-compose || true
  sudo pip install ansible

  docker info
  docker-compose --version
  ansible --version
}

main
