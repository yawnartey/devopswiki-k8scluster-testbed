# Security group definitions — all rules managed as standalone aws_security_group_rule resources

resource "aws_security_group" "cluster_nodes_sg" {
  name        = "DevOpsWiKi Cluster Nodes SG"
  description = "Allow intra-cluster SSH"
  vpc_id      = var.vpc_id
  tags = {
    Name = "DevOpsWiKi Cluster Nodes SG"
  }
}

resource "aws_security_group" "testbed-cp-sg" {
  name        = "DevOpsWiKi Testbed Control Plane SG"
  description = "Control Plane SG"
  vpc_id      = var.vpc_id
  tags = {
    Name = "DevOpsWiKi Testbed Control Plane SG"
  }
}

resource "aws_security_group" "testbed-fe-worker-node-sg" {
  name        = "DevOpsWiKi Testbed FE Worker Node SG"
  description = "Frontend Worker Node Security group definitions"
  vpc_id      = var.vpc_id
  tags = {
    Name = "DevOpsWiKi Testbed FE Worker Node SG"
  }
}

resource "aws_security_group" "testbed-be-worker-node-sg" {
  name        = "DevOpsWiKi Testbed BE Worker Node SG"
  description = "Backend worker node security group definitions"
  vpc_id      = var.vpc_id
  tags = {
    Name = "DevOpsWiKi Testbed BE Worker Node SG"
  }
}

# cluster_nodes_sg rules

resource "aws_security_group_rule" "cluster_nodes_ssh" {
  type              = "ingress"
  description       = "Allow SSH from any cluster node"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster_nodes_sg.id
  self              = true
}

resource "aws_security_group_rule" "cluster_nodes_bgp" {
  type              = "ingress"
  description       = "Calico BGP between cluster nodes"
  from_port         = 179
  to_port           = 179
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster_nodes_sg.id
  self              = true
}

resource "aws_security_group_rule" "cluster_nodes_ipip" {
  type              = "ingress"
  description       = "Calico IPIP between cluster nodes"
  from_port         = 0
  to_port           = 0
  protocol          = "4"
  security_group_id = aws_security_group.cluster_nodes_sg.id
  self              = true
}

resource "aws_security_group_rule" "cluster_nodes_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.cluster_nodes_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# control plane rules

resource "aws_security_group_rule" "cp_etcd" {
  type              = "ingress"
  description       = "etcd server for control plane only"
  from_port         = 2379
  to_port           = 2380
  protocol          = "tcp"
  security_group_id = aws_security_group.testbed-cp-sg.id
  self              = true
}

resource "aws_security_group_rule" "cp_allow_kube_apiserver_from_fe" {
  type                     = "ingress"
  description              = "Allow frontend worker node to access the kube-apiserver on the control plane"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.testbed-cp-sg.id
  source_security_group_id = aws_security_group.testbed-fe-worker-node-sg.id
}

resource "aws_security_group_rule" "cp_allow_kube_apiserver_from_be" {
  type                     = "ingress"
  description              = "Allow backend worker node to access the kube-apiserver on the control plane"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.testbed-cp-sg.id
  source_security_group_id = aws_security_group.testbed-be-worker-node-sg.id
}

resource "aws_security_group_rule" "cp_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.testbed-cp-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# frontend worker node rules

resource "aws_security_group_rule" "fe_worker_ssh" {
  type              = "ingress"
  description       = "SSH from external"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.testbed-fe-worker-node-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "fe_worker_http" {
  type              = "ingress"
  description       = "HTTP from internet"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.testbed-fe-worker-node-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "fe_worker_https" {
  type              = "ingress"
  description       = "HTTPS from the internet"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.testbed-fe-worker-node-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "fe_allow_kubelet_from_cp" {
  type                     = "ingress"
  description              = "Allow control plane to access kubelet on frontend worker nodes"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.testbed-fe-worker-node-sg.id
  source_security_group_id = aws_security_group.testbed-cp-sg.id
}

resource "aws_security_group_rule" "fe_worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.testbed-fe-worker-node-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# backend worker node rules

resource "aws_security_group_rule" "be_allow_kubelet_from_cp" {
  type                     = "ingress"
  description              = "Allow control plane to access kubelet on backend worker nodes"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.testbed-be-worker-node-sg.id
  source_security_group_id = aws_security_group.testbed-cp-sg.id
}

resource "aws_security_group_rule" "be_worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.testbed-be-worker-node-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}
