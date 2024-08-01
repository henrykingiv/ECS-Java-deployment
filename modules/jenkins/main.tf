resource "aws_instance" "jenkins" {
  ami                     = var.ami
  instance_type           = "t3.medium"
  subnet_id = var.subnet-id
  vpc_security_group_ids = [var.jenkins-sg]
  iam_instance_profile = aws_iam_instance_profile.jenkins_ssm_profile.name
  key_name = var.key-name
  user_data = local.jenkins_user_data
  root_block_device {
    volume_size = 15
    volume_type = "gp3"  # Optionally specify volume type (gp2, gp3, io1, etc.)
  }

  tags = {
    Name = var.jenkins-name
  }
}

resource "aws_iam_instance_profile" "jenkins_ssm_profile" {
  name = "jenkins_ssm_profile"
  role = var.iam-role-name
}

resource "aws_elb" "jenkins-lb" {
  name               = "jenkins-lb"
  subnets = var.subnet-elb
  security_groups = [var.jenkins-sg]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 443
    lb_protocol       = "https"
    ssl_certificate_id = var.cert-arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8080"
    interval            = 30
  }

  instances                   = [aws_instance.jenkins.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "jenkins-elb"
  }
}