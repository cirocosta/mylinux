VERSION             := $(shell cat ./VERSION)
COMMIT_SHA          := $(shell git rev-parse --short HEAD)
VAGRANT_IMAGE       := mylinux-$(VERSION)
DOCKER_FINAL_IMAGE  := cirocosta/mylinux
ANSIBLE_ROLES_PATH  := $(shell realpath ./ansible/roles)


run-aws-instance:
	cd ./aws && \
		terraform apply \
			-var "ami-version=$(VERSION)"


run-vagrant-build-machine:
	cd ./vagrant/build && \
		vagrant up


provision-vagrant-build-machine:
	cd ./vagrant/build && \
		vagrant provision


build-aws-ami:
	cd ./aws && \
		packer build \
			-var ansible_roles_path=$(ANSIBLE_ROLES_PATH) \
			-var version=$(VERSION) \
			./ami.json


build-vagrant-image: 
	cd ./vagrant/build && \
		vagrant package --output $(VAGRANT_IMAGE).box
	cd ./vagrant/build && \
		vagrant box add $(VAGRANT_IMAGE) $(VAGRANT_IMAGE).box


image:
	docker build \
		-t $(DOCKER_FINAL_IMAGE):$(VERSION) \
		.
	docker tag \
		$(DOCKER_FINAL_IMAGE):$(VERSION) \
		$(DOCKER_FINAL_IMAGE):$(VERSION)-$(COMMIT_SHA)
	docker tag \
		$(DOCKER_FINAL_IMAGE):$(VERSION) \
		$(DOCKER_FINAL_IMAGE):latest


login:
	echo $(DOCKER_PASSWORD) | docker login \
		--username $(DOCKER_USERNAME) \
		--password-stdin


push: login
	docker push $(DOCKER_FINAL_IMAGE):$(VERSION) 
	docker push $(DOCKER_FINAL_IMAGE):$(VERSION)-$(COMMIT_SHA)
	docker push $(DOCKER_FINAL_IMAGE):latest

