#vpc

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}


#subnet
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.example.id
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

#Subnnet_association

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}



#security-group
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Security group for web instances"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#launch configuration
resource "aws_launch_configuration" "example" {
  name_prefix   = "webapp-lc-"
  image_id      = "ami-0f34c5ae932e6f0e4"  # Replace with your desired AMI ID
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  name                 = "webapp-asg"
  launch_configuration = aws_launch_configuration.example.name
  min_size             = 2
  max_size             = 5
  desired_capacity     = 2

  availability_zones = ["us-east-1b", "us-east-1c"]  # Replace with your desired availability zones

  tag {
    key                 = "Name"
    value               = "webapp-instance"
    propagate_at_launch = true
  }
}

#load-balancer
resource "aws_lb" "example" {
  name               = "webapp-lb"
  internal           = false
  load_balancer_type = "application"

  enable_deletion_protection = false

  subnets = [aws_subnet.public_subnet.id]
  enable_http2 = true
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "Hello, Autoscaling!"
    }
  }
}

resource "aws_instance" "rs1" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     =  aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name = aws_key_pair.deployer.id
  tags = {
  Name = "sonali"
  }
}