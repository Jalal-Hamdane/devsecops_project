provider "aws" {
  region                  = "us-east-1"  # Use a variable for region

}

resource "aws_instance" "devsecops" {
  ami                         = "ami-0e2c8caa4b6378d8c" # Ubuntu 22.04
  instance_type               = "t2.micro"

  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "DevSecOps-Instance"
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
      "sudo apt-get update",
      "sudo apt-get install -y python3-pip",
      "pip3 install ansible"
    ]
  }
}
