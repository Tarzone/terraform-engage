# Output ec2 Public IP
output "ec2_public_ip" {
  value = module.myapp-server.instance.public_ip
}