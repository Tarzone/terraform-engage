output "instance" {
    value = aws_instance.myapp-server
}

output "eip" {
    value = aws_eip.myapp-server-eip
}