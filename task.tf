provider "aws" {
  region     = "ap-south-1"
  profile    = "task171"
}

resource "aws_vpc" "vpcmain" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "nkvpc"
  }
}

resource "aws_subnet" "subnet1a" {
  vpc_id     = "${aws_vpc.vpcmain.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "nksubnet-1a"
  }
}

resource "aws_subnet" "subnet1b" {
  vpc_id     = "${aws_vpc.vpcmain.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "nksubnet-1b"
  }
}

resource "aws_internet_gateway" "mygw" {
  vpc_id = "${aws_vpc.vpcmain.id}"

  tags = {
    Name = "nk_internet_gw"
  }
}

resource "aws_route_table" "routingtable" {
  vpc_id = "${aws_vpc.vpcmain.id}"
  depends_on = [ aws_internet_gateway.mygw ]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.mygw.id}"
  }
}
 
 resource "aws_route_table_association" "sb-ass" {
  depends_on = [ aws_route_table.routingtable ]
  subnet_id      = "${aws_subnet.subnet1a.id}"
  route_table_id = "${aws_route_table.routingtable.id}"
} 

resource "aws_security_group" "security" {
  name        = "wp_db_security"
  description = "Allow wp mysql"
  vpc_id      =  "${aws_vpc.vpcmain.id}"


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks =  ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "wp-db_sg"
  }
}

resource "aws_instance" "mysql" {
  depends_on = [ aws_security_group.security ]
  ami           = "ami-0019ac6129392a0f2"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet1b.id}"
  key_name = "hcc81"
  availability_zone = "ap-south-1b"
  vpc_security_group_ids = [aws_security_group.security.id]

 tags = {
    Name = "mysql_os"
  }
}

resource "aws_instance" "wordpress" {
  depends_on = [ aws_security_group.security ]
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = "${aws_subnet.subnet1a.id}"
  key_name = "hcc81"
  availability_zone = "ap-south-1a"
  vpc_security_group_ids = [aws_security_group.security.id]

  tags = {
    Name = "wp_os"
  }
}	
