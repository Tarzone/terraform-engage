# Output AMI ID
output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

# Output ec2 Public IP
output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}