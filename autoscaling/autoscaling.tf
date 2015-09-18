provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "terraform" {
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "terraform"
  }
}

resource "aws_subnet" "front" {
  vpc_id = "${aws_vpc.terraform.id}"
  cidr_block = "10.0.1.0/24"
  tags {
    Name = "front"
  }
}

resource "aws_elb" "micro-1-elb" {
  name = "micro-1-elb"
  subnets = ["${aws_subnet.front.id}"]
  internal = true
  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8000/"
    interval = 30 
  }
  tags {
    Name = "micro-1-elb"
  }
}

resource "aws_launch_configuration" "micro-1-conf" {
  image_id = "ami-408c7f28"
  instance_type = "t1.micro"
}

resource "aws_autoscaling_group" "micro-1" {
  name = "micro-1"
  min_size = 1
  max_size = 4
  desired_capacity = 2
  launch_configuration = "${aws_launch_configuration.micro-1-conf.name}"
  load_balancers = ["${aws_elb.micro-1-elb.name}"]
  vpc_zone_identifier = ["${aws_subnet.front.id}"]
  tag {
    key = "Name"
    value = "micro-1"
    propagate_at_launch = true
  }
}
