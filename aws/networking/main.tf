# vpc
resource "aws_vpc" "devopswiki-testbed-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "DevOpsWiKi Testbed VPC"
  }
}

# internet gateway
resource "aws_internet_gateway" "devopswiki-testbed-igw" {
  vpc_id = aws_vpc.devopswiki-testbed-vpc.id
  tags = {
    Name = "DevOpsWiKi Testbed IGW"
  }
}

# control plane private subnet
resource "aws_subnet" "testbed-cp-subnet" {
  vpc_id                  = aws_vpc.devopswiki-testbed-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = false
  tags = {
    Name = "DevOpsWiKi Testbed Control Plane Subnet"
  }
}

# frontend worker node public subnet 
resource "aws_subnet" "testbed-fe-subnet" {
  vpc_id                  = aws_vpc.devopswiki-testbed-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-3b"
  map_public_ip_on_launch = true
  tags = {
    Name = "DevOpsWiKi Testbed FE Worker Node Subnet"
  }
}

# backend worker node private subnet
resource "aws_subnet" "testbed-be-subnet" {
  vpc_id                  = aws_vpc.devopswiki-testbed-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-3c"
  map_public_ip_on_launch = false
  tags = {
    Name = "DevOpsWiKi Testbed BE Worker Node Subnet"
  }
}

# elastic ip for nat gateway 
resource "aws_eip" "devopswiki-testbed-nat-eip" {
  domain = "vpc"
  tags = {
    Name = "DevOpsWiKi Testbed NAT EIP"
  }
}

# nat gateway - in the public subnet for frontend worker node 
resource "aws_nat_gateway" "devopswiki-testbed-nat" {
  allocation_id = aws_eip.devopswiki-testbed-nat-eip.id
  subnet_id     = aws_subnet.testbed-fe-subnet.id
  tags = {
    Name = "DevOpsWiKi Testbed NAT"
  }
}

# public route table for testbed-fe-subnet
resource "aws_route_table" "testbed-fe-route-table" {
  vpc_id = aws_vpc.devopswiki-testbed-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devopswiki-testbed-igw.id
  }
  tags = {
    Name = "DevOpsWiKi Testbed Control Plane Route Table"
  }
}

# private route table for control plane and backend worker nodes
resource "aws_route_table" "testbed-ws-route-table" {
  vpc_id = aws_vpc.devopswiki-testbed-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.devopswiki-testbed-nat.id
  }
  tags = {
    Name = "DevOpsWiKi Testbed Control Plane & FE Worker node"
  }
}

# associate public route table to frontend public subnet
resource "aws_route_table_association" "testbed-fe-rt-association" {
  subnet_id      = aws_subnet.testbed-fe-subnet.id
  route_table_id = aws_route_table.testbed-fe-route-table.id
}

# associate control-plane subnet to private (NAT) route table
resource "aws_route_table_association" "testbed-cp-rt-association" {
  subnet_id      = aws_subnet.testbed-cp-subnet.id
  route_table_id = aws_route_table.testbed-ws-route-table.id
}

# associate backend worker subnet to private route table
resource "aws_route_table_association" "testbed-be-rt-association" {
  subnet_id      = aws_subnet.testbed-be-subnet.id
  route_table_id = aws_route_table.testbed-ws-route-table.id
}
