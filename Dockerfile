FROM ubuntu:bionic

RUN set -x && \
  apt update -y && \
  apt install -y ansible


ADD ./ansible /ansible


RUN set -x && \
  cd /ansible && \
  ansible-playbook \
    --inventory-file=./configuration/hosts \
    --connection=local \
    playbooks/provision-container.yml


RUN set -x && \
  apt-get purge \
    --auto-remove ansible -y


ENTRYPOINT [ "bash", "--login" ]
