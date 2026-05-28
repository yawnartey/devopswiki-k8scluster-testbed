output "vpc_id" {
  value = aws_vpc.devopswiki-testbed-vpc.id
}
output "subnet_ids" {
  description = "Map of subnet IDs to be used by compute"
  value = {
    "testbed-control-plane-subnet"  = aws_subnet.testbed-cp-subnet.id
    "testbed-fe-worker-node-subnet" = aws_subnet.testbed-fe-subnet.id
    "testbed-be-worker-node-subnet" = aws_subnet.testbed-be-subnet.id
  }
}
