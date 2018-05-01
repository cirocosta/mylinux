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

resource "aws_instance" "main" {
  instance_type = "t2.micro"
  ami           = "${data.aws_ami.mylinux.id}"
  key_name      = "${aws_key_pair.main.id}"

  vpc_security_group_ids = [
    "${aws_security_group.allow-ssh-and-egress.id}",
  ]
}

output "public-ip" {
  description = "Public IP of the instance created"
  value       = "${aws_instance.main.public_ip}"
}
