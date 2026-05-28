# iam role for frontend ec2
resource "aws_iam_role" "testbed_fe_instance_role" {
  name = "devopswiki-testbed-fe-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# allow s3 access to the letsencrypt bucket only
resource "aws_iam_role_policy" "testbed_fe_s3_policy" {
  name = "devopswiki-testbed-fe-s3-policy"
  role = aws_iam_role.testbed_fe_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource = [
        "arn:aws:s3:::devopswiki-testbed-letsencrypt-8daccc39b5d2c2e9",
        "arn:aws:s3:::devopswiki-testbed-letsencrypt-8daccc39b5d2c2e9/*"
      ]
    }]
  })
}

# instance profile to attach the role to the ec2
resource "aws_iam_instance_profile" "testbed_fe_instance_profile" {
  name = "devopswiki-testbed-fe-instance-profile"
  role = aws_iam_role.testbed_fe_instance_role.name
}
