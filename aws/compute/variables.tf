variable "subnet_ids" {
  type = map(string)
}
variable "testbed_cp_security_group_id" {
  type = string
}
variable "testbed_fe_security_group_id" {
  type = string
}
variable "testbed_be_security_group_id" {
  type = string
}
variable "cluster_nodes_sg" {
  type = string
}
variable "yaw_public_key" {
  type = string
}
variable "yaw_priv_key" {
  type = string
}
variable "postgres_user" {
  type = string
}
variable "postgres_password" {
  type = string
}
variable "testbed_fe_instance_profile" {
  type = string
}
