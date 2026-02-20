variable "bucket_base_name" {
  description = "Base name for the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Dev, Prod, etc. "
  type        = string
  default     = "dev"
}