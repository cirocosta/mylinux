1.  Fetch the iso

  curl \
    -SL \
    -o ubuntu-18.04.iso \
    http://releases.ubuntu.com/bionic/ubuntu-18.04-live-server-amd64.iso


2.  Install packer

  curl \
    -SL \
    -o packer.zip \
    https://releases.hashicorp.com/packer/1.2.4/packer_1.2.4_linux_amd64.zip
  unzip ./packer.zip
  sudo mv ./packer /usr/local/bin/packer


3.  Install dependencies
  apt install -y \
    qemu-kvm \
    libvirt-bin \
    bridge-utils \
    cloud-utils


4.  Create a cloud-init configuration file
  
  echo "#cloud-config
password: ubuntu
ssh_pwauth: true
chpasswd:
  expire: false" > cloud-init.cfg


5.  Create the disk image with the cloud-init configuration

  cloud-localds \
    ./disk-image.img \
    ./cloud-init.cfg


6. Run Packer

  See ./packer.json

7. 

  
