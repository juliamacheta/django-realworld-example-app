terraform {
  backend "s3" {}
}
provider "aws" {
region = "eu-west-2"
}
variable "vpc_cidr_block" {default = "10.0.0.0/16"}
variable "project_name" {}
variable "domain" {}
variable "networks" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  default = {
    n0 = {
      cidr_block        = "10.0.0.0/24"
      availability_zone = "eu-west-2a"
    }
    n1 = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "eu-west-2b"
    }
    n2 = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "eu-west-2c"
    }
  }
}



resource "aws_s3_bucket" "kops_state" {
  bucket        = "kopsstate.djangoapp.gotania.info"
  acl           = "private"
  force_destroy = true
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags = "${
    map(
     "Name", "${var.project_name}"
    )
  }"
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "subnets" {
  count = "${length(var.networks)}"
  availability_zone = "${var.networks["n${count.index}"].availability_zone}"
  cidr_block        = "${var.networks["n${count.index}"].cidr_block}"
  vpc_id            = "${aws_vpc.vpc.id}"
  tags = "${
    map(
     "Name", "${var.project_name}"
    )
  }"
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "${var.project_name}"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }
}

resource "aws_route_table_association" "route_table_association" {
  count = "${length(var.networks)}"
  subnet_id     = "${aws_subnet.subnets.*.id[count.index]}"
  route_table_id = "${aws_route_table.route_table.id}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

data "aws_subnet_ids" "subnet_ids" {
  depends_on = [
    aws_subnet.subnets
  ]
  vpc_id = aws_vpc.vpc.id
}

output "subnet_ids" {
  value = data.aws_subnet_ids.subnet_ids.ids.*
}

output "networks" {
  value = var.networks
}
