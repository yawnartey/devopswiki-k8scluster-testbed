output "bucket_name" {
  value = aws_s3_bucket.devopswiki_testbed_tf_state.id
}
output "bucket_name_2" {
  value = aws_s3_bucket.devopswiki_testbed_letsencrypt.id
}
