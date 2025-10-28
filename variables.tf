variable "tw_token" {
  description = "Timeweb Cloud API token"
  type        = string
}

variable "project_id" {
  description = "Timeweb Cloud project ID"
  type        = number
}

variable "ssh_key_id" {
  description = "Timeweb Cloud SSH key ID"
  type        = number
}

variable "private_key_path" {
  description = "Path to key for SSH"
  type        = string
}
