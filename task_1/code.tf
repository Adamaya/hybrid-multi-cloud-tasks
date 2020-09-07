provider "aws" {
  region = "ap-south-1"
  profile = "adamaya"
}

resource "aws_key_pair" "instance1-key"{
  key_name = "instance-key1"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41"
}

resource "aws_security_group" "allow_http_ssh" {
  name        = "allow_http_ssh"
  description = "Allow Tcp inbound traffic"
  vpc_id      = "vpc-3fe8f557"

  ingress {
    description = "http permission"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh permission"
    from_port   = 22
    to_port     = 22
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
    Name = "allow_http_ssh"
  }  
}

resource "aws_instance" "instance1" {
  ami             = "ami-0447a12f28fddb066"
  instance_type   = "t2.micro"
  key_name        = "instance-key1"
  security_groups = ["allow_http_ssh"]
    user_data = <<-EOF
              #! bin/bash
              sudo yum install httpd php git -y
              sudo systemctl enable httpd
              sudo systemctl start httpd
              sudo mkfs.ext4 /dev/xvdb
              sudo mount /dev/xvdb /var/www/html/
              sudo git clone https://github.com/Adamaya/ec2_s3_cloudfront_provision_by_terraform.git /var/www/html/
          EOF  
  tags = {
    Name = "instance1"
  }
}

resource "aws_ebs_volume" "instance1-volume" {
  availability_zone = "ap-south-1a"
  size              = 1

  tags = {
    Name = "instance1-volume"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.instance1-volume.id}"
  instance_id = "${aws_instance.instance1.id}"
  force_detach = true

}

resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.instance1.public_ip} > publicip.txt"
  	}
}

resource "aws_s3_bucket" "b" {
  bucket = "instance1-buck"
  acl = "public-read"
}

resource "aws_s3_bucket_policy" "b" {
  bucket = "${aws_s3_bucket.b.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "MYBUCKETPOLICY",
  "Statement": [
    {
      "Sid": "IPAllow",
      "Effect": "allow",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::instance1-buck/*"
    }
  ]
}
POLICY
}


resource "aws_s3_bucket_object" "object" {
  bucket = "instance1-buck"
  key    = "iot.jpg"
  source = "C:/Users/ADAMAYA SHARMA/Downloads/Compressed/iot.jpg"

}

locals {
  s3_origin_id = "S3-instance1-buck"
}

resource "aws_cloudfront_distribution" "cloudfront_dist" {
  origin {
    domain_name = aws_s3_bucket.b.bucket_regional_domain_name
    origin_id   = local.s3_origin_id


    custom_origin_config {
      http_port = 80
      https_port = 80
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  
  enabled = true


  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id


    forwarded_values {
      query_string = false


      cookies {
        forward = "none"
      }
    }


    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }


  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


output "Instance-Public-IP" {
	value = aws_instance.instance1.public_ip
}