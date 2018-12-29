mylinux

        Vagrant box, Docker container, AWS AMI, Terraform configuration
        and ansible scripts that provision my Linux setup.


USAGE

        - Creating a vagrant box:

                make run-varant-build-machine
                make build-vagrant-image


        - Creating a docker image:

                make image


        - Creating an AWS AMI

                make build-aws-ami


        - Running an AWS instance with the last mylinux
          AMI build (account independent):

                make run aws-instance


        - Running the Docker container:

                docker run -it cirocosta/mylinux


        - Running the Vagrant box:

                Vagrant.configure(2) do |config|
                  config.ssh.username = "ubuntu"

                  config.vm.box = "mylinux-v0.0.5"
                  config.vm.box_check_update = false

                  config.vm.provider "virtualbox" do |v|
                    v.memory = 2048
                    v.cpus = 3
                  end
                end


DEPENDENCIES
        Vagrant:
                - vagrant
                - vagrant-disksize

        Docker:
                - docker

        AWS:
                - packer
                - awscli
