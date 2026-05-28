# Cluster-wide SSH security group
resource "aws_security_group" "cluster_nodes_sg" {
  name        = "DevOpsWiKi Cluster Nodes SG"
  description = "Allow intra-cluster SSH"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH from any cluster node"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevOpsWiKi Cluster Nodes SG"
  }
}

# control plane security group
resource "aws_security_group" "testbed-cp-sg" {
  name        = "DevOpsWiKi Testbed Control Plane SG"
  description = "Control Plane SG"
  vpc_id      = var.vpc_id

  ingress {
    description = "etcd server for control plane only"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevOpsWiKi Testbed Control Plane SG"
  }
}

# frontend worker node security group
resource "aws_security_group" "testbed-fe-worker-node-sg" {
  name        = "DevOpsWiKi Testbed FE Worker Node SG"
  description = "Frontend Worker Node Security group definitions"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from external"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevOpsWiKi Testbed FE Worker Node SG"
  }
}

# backend worker node security group
resource "aws_security_group" "testbed-be-worker-node-sg" {
  name        = "DevOpsWiKi Testbed BE Worker Node SG"
  description = "Backend worker node security group definitions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevOpsWiKi Testbed BE Worker Node SG"
  }
}

# cross-SG rules, these are created separately to avoid cycles

# allow kube-apiserver on control-plane from frontend
resource "aws_security_group_rule" "cp_allow_kube_apiserver_from_fe" {
  type                     = "ingress"
  description              = "Allow frontend worker node to access the kube-apiserver on the control plane"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.testbed-cp-sg.id
  source_security_group_id = aws_security_group.testbed-fe-worker-node-sg.id
}

# allow kube-apiserver on control-plane from backend
resource "aws_security_group_rule" "cp_allow_kube_apiserver_from_be" {
  description              = "Allow backend worker node to access the kube-apiserver on the control plane"
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.testbed-cp-sg.id
  source_security_group_id = aws_security_group.testbed-be-worker-node-sg.id
}

# allow kubelet on workers from control plane
resource "aws_security_group_rule" "fe_allow_kubelet_from_cp" {
  type                     = "ingress"
  description              = "Allow control plane to access kubelet on frontend worker nodes"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.testbed-fe-worker-node-sg.id
  source_security_group_id = aws_security_group.testbed-cp-sg.id
}

resource "aws_security_group_rule" "be_allow_kubelet_from_cp" {
  type                     = "ingress"
  description              = "Allow control plane to access kubelet on backend worker nodes"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.testbed-be-worker-node-sg.id
  source_security_group_id = aws_security_group.testbed-cp-sg.id
}
