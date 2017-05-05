## GoCD agent hosts + launch config + autoscaling group + security group

# Security group

resource "aws_security_group" "gocdagt_hst" {
  name        = "${var.env_name}-gocdagt-hst"
  vpc_id      = "${aws_vpc.rancher.id}"
  description = "GoCD agent hosts"

  ingress {
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8153
    to_port     = 8154
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.env_name}-gocdagt-hst"
  }
}

# User-data template
data "template_file" "userdata_gocdagt_hst" {
  template = "${file("./files/userdata_gocdagt_hst.template")}"

  vars {
    # HostsReg
    env_name  = "${var.env_name}"
    dns_zone  = "${var.dns_zone}"
    reg_token = "${var.reg_token}"
  }
}

# Launch configuration

resource "aws_launch_configuration" "gocdagt_hst" {
  image_id                    = "${lookup(var.ami_type, var.aws_region)}"
  instance_type               = "${var.gocdagt_hst_size}"
  key_name                    = "${var.key_name}"
  security_groups             = ["${aws_security_group.gocdagt_hst.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.rancher.id}"
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  depends_on = ["aws_internet_gateway.igw"]

  user_data = "${data.template_file.userdata_gocdagt_hst.rendered}"
}

# Autoscaling group

resource "aws_autoscaling_group" "gocdagt_hst" {
  name                      = "${var.env_name}-gocdagt-hst"
  availability_zones        = ["${var.aws_region}a","${var.aws_region}b"]
  launch_configuration      = "${aws_launch_configuration.gocdagt_hst.name}"
  health_check_grace_period = 500
  health_check_type         = "EC2"
  max_size                  = "${var.gocdagt_hst_max}"
  min_size                  = "${var.gocdagt_hst_min}"
  desired_capacity          = "${var.gocdagt_hst_des}"
  vpc_zone_identifier       = ["${aws_subnet.pub_a.id}","${aws_subnet.pub_b.id}"]

  tag {
    key                 = "Name"
    value               = "${var.env_name}-gocdagt-hst"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = ["aws_launch_configuration.gocdagt_hst"]
}
