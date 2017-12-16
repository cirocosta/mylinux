mylinux - Vagrant box, Dockerfile and ansible scripts that provision
          my Linux setup.

Testing:

  Testing is performed via docker:
      - creates a docker contaneiner which simulates an Ubuntu:zesty
        setup which becomes the target of a local ansible process.

  In order to spawn the execution of the test, run:

      make test-ansible


Running:
  
  Docker:
      - docker run --name inst --detach --privileged cirocosta/mylinux
      - docker exec -it inst /bin/bash

      


