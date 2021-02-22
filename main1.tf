
# Configure the AWS Provider

 }
#1.	Create vpc 
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
      Name = "prod-vpc"
  }
}
#2.	Create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "prod-vpc"
  }
}
#3.	Create custom route table 
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "production"
  }
}
#4.	Crate a subnet 
resource "aws_subnet" "subnet1"
    vpc_id = "aws_vpc.prod-vpc.id"
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "prod-subnet"
    }

#5Associate subnet with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.prod-route-table.id
}

#6.	Create security group to allow port 22, 80, 443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "Https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [0.0.0.0/0] 
     }
    ingress {
    description = "Http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [0.0.0.0/0] 
     }
    ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [0.0.0.0/0]
      }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}


#7.	Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "webserver" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group. allow_web.id]

  
}
#8.	Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.webserver.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = aws_internet_gateway.gw   # no need to specify id 
}

#9.	Create ubuntu server and install enable apache. 

resource "aws_instance" "web-ubuntu"{
    ami (aws-aws_instance) = "ami-0885b1f6bd170450c"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "Dec2020Devops"
    
    network_interface {
        device_index = 0
        aws_network_interface_id = aws_network_interface.webserver.id

        }
    user_data = <<-EOF
        #!/bin/bash
        sudo apt update -y
        sudo apt install apache2 -y
        sudo systemctl start apache2
        sudo bash -c ' echo your very first web server > /var/www/html/index.html'
        EOF
    tags = { 
        Name = "web-server"
    }
}


