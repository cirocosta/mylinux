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

# Retrieve the default VPC for the specified region
# such that we don't need to set up an entire vpc
# with all the necessary configurations for a quick
# test.
data "aws_vpc" "main" {
  default = true
}

# Public key to use as an authorized key in the instances
# that we provision such that we can SSH into them if needed.
resource "aws_key_pair" "main" {
  key_name_prefix = "key"
  public_key      = "${file("./keys/key.rsa.pub")}"
}

# Create a security group that will allow us to both
# SSH into the instance as well as access prometheus
# publicly (note.: you'd not do this in prod - otherwise
# you'd have prometheus publicly exposed).
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

# Create an instance in the default VPC with a specified
# SSH key so we can properly SSH into it to verify whether
# everything is worked as intended.
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
