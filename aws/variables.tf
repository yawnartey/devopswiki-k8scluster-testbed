variable "yaw_public_key" {
  type = string
}
variable "yaw_priv_key" {
  type = string
}
variable "postgres_user" {
  type      = string
  sensitive = true
}
variable "postgres_password" {
  type      = string
  sensitive = true
}
