VERSION 								:= $(shell cat ./VERSION)
DOCKER_BASE_IMAGE 			:= cirocosta/ubuntu
DOCKER_FINAL_IMAGE 			:= cirocosta/mylinux
DOCKER_CONTAINER 				:= test_ansible_container
COMMIT_SHA							:= $(shell git rev-parse --short HEAD)
SSH_PRIVATE_KEY 				:= $(shell realpath ./keys/key.rsa)
SSH_PUBLIC_KEY 					:= $(shell realpath ./keys/key.rsa.pub)
ANSIBLE_ROLES_PATH 			:= $(shell realpath ./ansible/roles)
VAGRANT_IMAGE 					:= mylinux-$(VERSION)


run-vagrant-build-machine:
	cd ./vagrant/build && \
		vagrant up


provision-vagrant-build-machine:
	cd ./vagrant/build && \
		vagrant provision


build-vagrant-image: 
	cd ./vagrant/build && \
		vagrant package --output $(VAGRANT_IMAGE).box
	cd ./vagrant/build && \
		vagrant box add $(VAGRANT_IMAGE) $(VAGRANT_IMAGE).box


commit-docker-image:
	docker commit $(DOCKER_CONTAINER) $(DOCKER_FINAL_IMAGE):$(VERSION)
	docker tag $(DOCKER_FINAL_IMAGE):$(VERSION) $(DOCKER_FINAL_IMAGE):$(VERSION)-$(COMMIT_SHA)
	docker tag $(DOCKER_FINAL_IMAGE):$(VERSION) $(DOCKER_FINAL_IMAGE):latest


push-docker-image:
	docker push $(DOCKER_FINAL_IMAGE):$(VERSION) 
	docker push $(DOCKER_FINAL_IMAGE):$(VERSION)-$(COMMIT_SHA)
	docker push $(DOCKER_FINAL_IMAGE):latest


run-docker-container:
	docker rm -f $(DOCKER_CONTAINER) || true
	sudo chown root:root $(SSH_PUBLIC_KEY)
	docker run \
		--privileged \
		--security-opt seccomp=unconfined \
		--tmpfs /run \
		--tmpfs /run/lock \
		--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
		--volume $(SSH_PUBLIC_KEY):/root/.ssh/authorized_keys:ro \
		--detach \
		--publish 2222:22 \
		--publish 9100:9100 \
		--publish 9101:9101 \
		--name $(DOCKER_CONTAINER) \
		$(DOCKER_BASE_IMAGE)
	sleep 3


provision-docker-container:
	chmod 400 $(SSH_PRIVATE_KEY)
	cd ./ansible && \
		ansible-playbook \
			--inventory-file=./configuration/hosts \
			--private-key=$(SSH_PRIVATE_KEY) \
			playbooks/test-docker.yml


test-ansible: | run-docker-container provision-docker-container

.PHONY: test-ansible
