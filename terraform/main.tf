provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "devsecops_sg" {
  name        = "devsecops-sg"
  description = "Autoriser le SSH et HTTP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "devsecops" {
  ami               = "ami-0e2c8caa4b6378d8c"  # Ubuntu 22.04
  instance_type     = "t2.micro"
  key_name          = var.key_name
  security_groups   = [aws_security_group.devsecops_sg.name]
  associate_public_ip_address = true

  tags = {
    Name = "DevSecOps-Instanc"
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > instance_ip.txt"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y software-properties-common",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt-get install -y ansible"
    ]
  }
}
