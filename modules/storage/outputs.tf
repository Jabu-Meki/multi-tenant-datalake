output "bucket_name" {
  description = "Name (ID) of the data lake S3 bucket"
  value       = aws_s3_bucket.datalake_bucket.id
}

output "bucket_arn" {
  description = "ARN of the data lake S3 bucket"
  value       = aws_s3_bucket.datalake_bucket.arn
}
