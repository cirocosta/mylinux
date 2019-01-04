mylinux

        Vagrant box, Docker container, AWS AMI, Terraform configuration
        and ansible scripts that provision my Linux setup.


USAGE
        - Provisioning a local Linux machine

                apt update && apt install -y ansible
                cd ansible && \
                        ansible-playbook \
                                --extra-vars=user=myuser \
                                --extra-vars=user_home=/home/myuser \
                                --connection=local \
                                playbooks/provision-local.yml


        - Creating a vagrant box:

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

                1. Create a Vagrantfile

                        Vagrant.configure(2) do |config|
                          config.vm.hostname = 'bionic'

                          config.vm.box = "mylinux-0.2.2"
                          config.vm.box_check_update = false

                          config.vm.provider "virtualbox" do |v|
                            v.memory = 2048
                            v.cpus = 3
                          end
                        end

                2. Get it up and SSH into it

                        vagrant up
                        vagrant ssh
                        sudo su - ubuntu


DEPENDENCIES

        Vagrant:
                - vagrant
                - vagrant-disksize

        Docker:
                - docker

        AWS:
                - packer
                - awscli
