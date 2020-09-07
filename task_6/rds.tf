#Configure AWS Provider
provider "aws" {  
region  = "ap-south-1"  
profile = "adamaya"
}

#Creating RDS Instance
resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "WordPressDatabase"
  username             = "adams"
  password             = "adams123"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
  #Allowing Public Access
  publicly_accessible = true
  #Attaching VPC Security Group
  vpc_security_group_ids = [aws_security_group.security-group.id]
  apply_immediately = true
  tags = {
  Name = "task6"
  }
}


#Creating Security Group to allow Minikube to connect to RDS
resource "aws_security_group" "security-group" {
  name        = "RDS Security Group"
  description = "Allow 3306 inbound traffic only for the public ip of the machine running this code"

  ingress {
    description = "3306 from Minikube"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS"
  }
}

#Output DNS Name of RDS Instance
output "dns" {
value = aws_db_instance.default.address
}