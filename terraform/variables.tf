variable "region" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "docdb_username" {
  description = "DocumentDB username"
  default     = "flaskadmin" # Changé de "admin" à "flaskadmin"
}

variable "docdb_password" {
  description = "DocumentDB password"
  default     = "securepassword123"
  sensitive   = true
}
