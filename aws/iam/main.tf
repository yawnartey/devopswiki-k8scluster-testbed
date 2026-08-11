# iam role for frontend/control-plane ec2
resource "aws_iam_role" "testbed_k8s_fe_instance_role" {
  name = "devopswiki-testbed-k8s-fe-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# iam role for backend ec2
resource "aws_iam_role" "testbed_k8s_be_instance_role" {
  name = "devopswiki-testbed-k8s-be-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# s3 policy for letsencrypt — fe/cp only
resource "aws_iam_role_policy" "testbed_k8s_fe_s3_policy" {
  name = "devopswiki-testbed-k8s-fe-s3-policy"
  role = aws_iam_role.testbed_k8s_fe_instance_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource = [
        "arn:aws:s3:::devops-wiki-letsencrypt-c9123c3a736c3547",
        "arn:aws:s3:::devops-wiki-letsencrypt-c9123c3a736c3547/*"
      ]
    }]
  })
}

# shared ebs csi managed policy — attached to both roles
resource "aws_iam_policy" "testbed_k8s_ebs_csi_policy" {
  name = "devopswiki-testbed-k8s-ebs-csi-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:CreateVolume",
        "ec2:DeleteVolume",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumeStatus",
        "ec2:DescribeVolumesModifications",
        "ec2:DescribeInstances",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeTags",
        "ec2:CreateTags"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "fe_ebs_csi" {
  role       = aws_iam_role.testbed_k8s_fe_instance_role.name
  policy_arn = aws_iam_policy.testbed_k8s_ebs_csi_policy.arn
}

resource "aws_iam_role_policy_attachment" "be_ebs_csi" {
  role       = aws_iam_role.testbed_k8s_be_instance_role.name
  policy_arn = aws_iam_policy.testbed_k8s_ebs_csi_policy.arn
}

# instance profiles
resource "aws_iam_instance_profile" "testbed_k8s_fe_instance_profile" {
  name = "devopswiki-testbed-k8s-fe-instance-profile"
  role = aws_iam_role.testbed_k8s_fe_instance_role.name
}

resource "aws_iam_instance_profile" "testbed_k8s_be_instance_profile" {
  name = "devopswiki-testbed-k8s-be-instance-profile"
  role = aws_iam_role.testbed_k8s_be_instance_role.name
}
