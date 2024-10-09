# Output ec2 Public IP
output "ec2_public_ip" {
  value = module.myapp-server.instance.public_ip
}

output "eip_allocation_id" {
  value = module.myapp-server.eip.allocation_id
}

output "eip_association_id" {
  value = module.myapp-server.eip.association_id
}

output "eip_vpc" {
  value = module.myapp-server.eip.vpc
}

output "eip_public_ip" {
  value = module.myapp-server.eip.public_ip
}