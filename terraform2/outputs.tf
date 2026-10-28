output "server_ip_1" {
  value = aws_instance.my_server_1.public_ip
}

output "server_ip_2" {
  value = aws_instance.my_server_2.public_ip
}

output "server_ip_private" {
  value = aws_instance.my_server_private.public_ip
}

output "ssm_command_1" {
  value = "aws ssm start-session --target ${aws_instance.my_server_1.id}"
}

output "ssm_command_2" {
  value = "aws ssm start-session --target ${aws_instance.my_server_2.id}"
}

output "ssm_command_private" {
  value = "aws ssm start-session --target ${aws_instance.my_server_private.id}"
}