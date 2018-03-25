VERSION             := $(shell cat ./VERSION)
DOCKER_BASE_IMAGE   := ubuntu:artful
DOCKER_FINAL_IMAGE  := cirocosta/mylinux
DOCKER_CONTAINER    := ansible_container
COMMIT_SHA          := $(shell git rev-parse --short HEAD)
ANSIBLE_ROLES_PATH  := $(shell realpath ./ansible/roles)
VAGRANT_IMAGE       := mylinux-$(VERSION)


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
	docker run \
		--name $(DOCKER_CONTAINER) \
		--tty \
		--detach \
		$(DOCKER_BASE_IMAGE)


provision-docker-container:
	cd ./ansible && \
		ansible-playbook \
			--inventory-file=./configuration/hosts \
			playbooks/provision-docker.yml


build-container: | run-docker-container provision-docker-container

.PHONY: build-container
