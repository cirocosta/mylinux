VERSION             := $(shell cat ./VERSION)
COMMIT_SHA          := $(shell git rev-parse --short HEAD)
VAGRANT_IMAGE       := mylinux-$(VERSION)
DOCKER_FINAL_IMAGE  := cirocosta/mylinux
ANSIBLE_ROLES_PATH  := $(shell realpath ./ansible/roles)


run-aws-instance:
	cd ./aws && \
		terraform apply \
			-var "ami-version=$(VERSION)"


destroy-aws-instance:
	cd ./aws && \
		terraform destroy \
			-var "ami-version=$(VERSION)"


run-vagrant-build-machine:
	cd ./vagrant/build && \
		vagrant up


provision-vagrant-build-machine:
	cd ./vagrant/build && \
		vagrant provision


ssh-into-aws: AWS_IP=$(shell \
	terraform output -state=./aws/terraform.tfstate public-ip)
ssh-into-aws:
	ssh -i ./aws/keys/key.rsa ubuntu@$(AWS_IP)


provision-minikube-aws: AWS_IP=$(shell \
	terraform output -state=./aws/terraform.tfstate public-ip)
provision-minikube-aws: AWS_KEY=$(shell \
	realpath ./aws/keys/key.rsa)
provision-minikube-aws:
	echo "aws ansible_host=$(AWS_IP) ansible_user=ubuntu" \
		> /tmp/ansible-hosts
	cd ./ansible && \
		ansible-playbook \
			--private-key=$(AWS_KEY) \
			--inventory /tmp/ansible-hosts \
			./playbooks/provision-minikube.yml


provision-vostro:
	cd ./ansible && \
		ansible-playbook \
			--ask-pass \
			--ask-become-pass \
			./playbooks/provision-vostro.yml

build-gcp-image:
	cd ./gcp && \
		packer build \
			-var ansible_roles_path=$(ANSIBLE_ROLES_PATH) \
			-var version=$(VERSION) \
			-var project-id=$(PROJECT_ID) \
			./image.json

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


build-kvm-image:
	cd ./kvm && \
		packer build \
			-var ansible_roles_path=$(ANSIBLE_ROLES_PATH) \
			./packer.json


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

