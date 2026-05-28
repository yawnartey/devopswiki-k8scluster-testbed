output "testbed_fe_eip" {
  value = aws_eip.devopswiki-testbed-fe-eip.public_ip
}
output "testbed_be_pip" {
  value = aws_instance.devopswiki-testbed-be.private_ip
}
output "testbed_cp_pip" {
  value = aws_instance.devopswiki-testbed-cp.private_ip
}
