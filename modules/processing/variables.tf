variable "bucket_arn" {
  description = "The ARN of the bucket (passed from the storage module)"
  type        = string
}

variable "bucket_id" {
  description = "The S3 bucket name/id for notifications"
  type        = string
}
