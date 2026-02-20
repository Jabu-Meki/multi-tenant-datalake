
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "datalake_bucket" {
  bucket = "${var.bucket_base_name}-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Multi-Tenant Data Lake"
    Environment = var.environment
    Project     = "Demo-Datalake"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "datalake" {
  bucket = aws_s3_bucket.datalake_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
  bucket = aws_s3_bucket.datalake_bucket.id

  rule {
    id     = "cleanup-raw-zone"
    status = "Enabled"
    filter {
      prefix = "raw/"
    }
    expiration {
      days = 7
    }
  }

  rule {
    id     = "cleanup-curated-zone"
    status = "Enabled"
    filter {
      prefix = "curated/"
    }
    expiration {
      days = 30
    }
  }
}


resource "aws_s3_bucket_public_access_block" "datalake" {
  bucket                  = aws_s3_bucket.datalake_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
