provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

data "aws_caller_identity" "current" {}

data "aws_ami" "mylinux" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "mylinux-${var.ami-version}-*",
    ]
  }

  owners = [
    "${data.aws_caller_identity.current.account_id}",
  ]
}

data "aws_vpc" "main" {
  default = true
}

resource "aws_key_pair" "main" {
  key_name_prefix = "key"
  public_key      = "${file("./keys/key.rsa.pub")}"
}

resource "aws_security_group" "allow-ssh-and-egress" {
  name = "main"

  description = "Allows ingress SSH traffic and egress to any address."
  vpc_id      = "${data.aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_ssh-and-egress"
  }
}

# TYPE       VCPU  MEM   $/10hrs
# ---------------------------
# t2.micro   1     1     0.19
# t2.medium  2     4     0.75
# c5.xlarge	 4	   8     2.62
resource "aws_instance" "main" {
  instance_type = "${var.instance-type}"
  ami           = "${data.aws_ami.mylinux.id}"
  key_name      = "${aws_key_pair.main.id}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = "25"
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.allow-ssh-and-egress.id}",
  ]
}

output "public-ip" {
  description = "Public IP of the instance created"
  value       = "${aws_instance.main.public_ip}"
}
