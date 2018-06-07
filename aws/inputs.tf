variable "region" {
  default = "us-east-1"
}

variable "instance-type" {
  default = "c5.xlarge"
}

variable "profile" {
  default = "beld"
}

variable "ami-version" {
  description = "Version of the AMI to be used"
}
