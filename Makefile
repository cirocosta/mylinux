ANSIBLE_ROLES_PATH  = $(shell realpath ./ansible/roles)
AWS_IP              = $(shell terraform output -state=./aws/terraform.tfstate public-ip)
AWS_KEY             = $(shell realpath ./aws/keys/key.rsa)
COMMIT_SHA          = $(shell git rev-parse --short HEAD)
VAGRANT_BOX         = mylinux.box
VAGRANT_IMAGE       = mylinux-$(shell cat ./VERSION)
VERSION             = $(shell cat ./VERSION)


run-aws-instance:
	cd ./aws && \
		terraform apply \
			-var "ami-version=$(VERSION)"


destroy-aws-instance:
	cd ./aws && \
		terraform destroy \
			-var "ami-version=$(VERSION)"


ssh-into-aws:
	ssh -i ./aws/keys/key.rsa ubuntu@$(AWS_IP)


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


.ONESHELL:
build-vagrant-image:
	cd ./vagrant/build
	find . -name "*.box" -delete
	vagrant up
	vagrant package --output $(VAGRANT_BOX)
	vagrant box add --force \
		$(VAGRANT_IMAGE) \
		$(VAGRANT_BOX)
	vagrant destroy -f



build-kvm-image:
	cd ./kvm && \
		packer build \
			-var ansible_roles_path=$(ANSIBLE_ROLES_PATH) \
			./packer.json


image:
	docker build \
		-t cirocosta/mylinux \
		.
