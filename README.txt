mylinux

    Bootstrap an Ubuntu machine with my minimal shell and development tools.

run

    ./provision.sh

remote run

    curl -fsSL https://raw.githubusercontent.com/cirocosta/mylinux/master/provision.sh | bash

vm test

    ./test-multipass.sh

    The test harness uses Multipass to launch a real Ubuntu VM, copy the
    provisioner, run it twice, and check the installed tools. Defaults:

        IMAGE=<host Ubuntu VERSION_ID>
        VM_NAME=mylinux-provision-test
        CPUS=2
        MEMORY=4G
        DISK=20G

    Keep the VM after a run:

        KEEP_VM=1 ./test-multipass.sh
