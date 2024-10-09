output "instance" {
    value = aws_instance.myapp-server
}

/*# Output newly created EIP
output "eip" {
    value = aws_eip.myapp-server-eip
}*/

# Output existing EIP
output "eip_alloc" {
    value = aws_eip_association.eip_assoc
}