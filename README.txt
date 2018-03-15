mylinux 

        Vagrant box, Docker container and ansible scripts that provision
        my Linux setup.


USAGE

        - Creating a vagrant box:
                
                make run-varant-build-machine
                make build-vagrant-image


        - Creating a docker image:

                make run-docker-container
                make provision-docker-container
                make commit-docker-image


        - Running the Docker container:

                docker run -it cirocosta/mylinux


        - Running the Vagrant box:

                Vagrant.configure(2) do |config|
                  config.ssh.username = "ubuntu"

                  config.vm.box = "mylinux-v0.0.1"
                  config.vm.box_check_update = false

                  config.vm.provider "virtualbox" do |v|
                    v.memory = 2048
                    v.cpus = 3
                  end
                end
