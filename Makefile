VERSION 								:=	$(shell cat ./VERSION)
DOCKER_IMAGE 						:=	cirocosta/ubuntu
DOCKER_TEST_CONTAINER 	:=	test_ansible_container
DOCKER_PRIVATE_KEY 			:=	$(shell realpath ./keys/key.rsa)
ANSIBLE_ROLES_PATH 			:=	$(shell realpath ./ansible/roles)


ami:
	cd ./aws && \
		packer build \
			-var ansible_roles_path=$(ANSIBLE_ROLES_PATH) \
			./packer.json


run-vagrant-build-machine:
	cd ./vagrant/build && \
		vagrant up


provision-vagrant-build-machine:
	cd ./vagrant/build && \
		vagrant provision


build-vagrant-image: 
	cd ./vagrant/build && \
		vagrant package --output wedeploy-$(VERSION).box
	cd ./vagrant/build && \
		vagrant box add wedeploy-$(VERSION) ./wedeploy-$(VERSION).box


run-docker-container:
	docker rm -f $(DOCKER_TEST_CONTAINER) || true
	docker run \
		--privileged \
		--security-opt seccomp=unconfined \
		--tmpfs /run \
		--tmpfs /run/lock \
		--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
		--detach \
		--publish 2222:22 \
		--publish 9100:9100 \
		--publish 9101:9101 \
		--name $(DOCKER_TEST_CONTAINER) \
		$(DOCKER_IMAGE)
	sleep 3


provision-docker-container:
	chmod 400 $(DOCKER_PRIVATE_KEY)
	cd ./ansible && \
		ansible-playbook \
			--inventory-file=./configuration/hosts \
			--private-key=$(DOCKER_PRIVATE_KEY) \
			playbooks/test-docker.yml


test-ansible: | run-docker-container provision-docker-container


.PHONY: test-ansible
