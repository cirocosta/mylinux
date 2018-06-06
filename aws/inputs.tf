variable "region" {
  default = "sa-east-1"
}

variable "instance-type" {
  default = "t2.medium"
}

variable "profile" {
  default = "beld"
}

variable "ami-version" {
  description = "Version of the AMI to be used"
}
