# control plane ec2 instance
resource "aws_instance" "devopswiki-testbed-cp" {
  ami                    = "ami-075518ffc9234909a"
  instance_type          = "t2.medium"
  subnet_id              = var.subnet_ids["testbed-control-plane-subnet"]
  vpc_security_group_ids = [var.testbed_cp_security_group_id, var.cluster_nodes_sg]
  iam_instance_profile   = var.testbed_fe_instance_profile
  user_data_base64 = base64encode(
    templatefile("${path.module}/scripts/bootstrap-testbed-cp.sh", {
      yaw_public_key    = var.yaw_public_key
      postgres_user     = var.postgres_user
      postgres_password = var.postgres_password
    })
  )

  tags = {
    Name = "DevOpsWiKi Testbed Control Plane Node"
  }
}


# frontend worker ec2 instance
resource "aws_instance" "devopswiki-testbed-fe" {
  ami                    = "ami-075518ffc9234909a"
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_ids["testbed-fe-worker-node-subnet"]
  vpc_security_group_ids = [var.testbed_fe_security_group_id, var.cluster_nodes_sg]
  iam_instance_profile   = var.testbed_fe_instance_profile
  user_data = templatefile("${path.module}/scripts/bootstrap-testbed-fe.sh", {
    be_private_ip     = aws_instance.devopswiki-testbed-be.private_ip
    cp_private_ip     = aws_instance.devopswiki-testbed-cp.private_ip
    yaw_public_key    = var.yaw_public_key
    yaw_priv_key      = var.yaw_priv_key
    postgres_user     = var.postgres_user
    postgres_password = var.postgres_password
  })
  tags = {
    Name = "DevOpsWiKi Testbed FE Worker Node"
  }
}

# backend worker ec2 instance
resource "aws_instance" "devopswiki-testbed-be" {
  ami                    = "ami-075518ffc9234909a"
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_ids["testbed-be-worker-node-subnet"]
  vpc_security_group_ids = [var.testbed_be_security_group_id, var.cluster_nodes_sg]
  user_data = templatefile("${path.module}/scripts/bootstrap-testbed-be.sh", {
    cp_private_ip     = aws_instance.devopswiki-testbed-cp.private_ip
    yaw_public_key    = var.yaw_public_key
    yaw_priv_key      = var.yaw_priv_key
    postgres_user     = var.postgres_user
    postgres_password = var.postgres_password
  })
  tags = {
    Name = "DevOpsWiKi Testbed BE Worker Node"
  }
}

# frontend eip
resource "aws_eip" "devopswiki-testbed-fe-eip" {
  domain   = "vpc"
  instance = aws_instance.devopswiki-testbed-fe.id
  tags     = { Name = "DevOpsWiKi Testbed FE Worker Node EIP" }
}
