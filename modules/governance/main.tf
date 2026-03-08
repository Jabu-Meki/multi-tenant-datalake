resource "aws_lakeformation_data_lake_settings" "admin" {
  admins = [data.aws_caller_identity.current.arn]
}

resource "aws_glue_catalog_database" "datalake_db" {
  name = "multi_tenant_datalake_${var.environment}"
}

data "aws_caller_identity" "current" {}

resource "aws_athena_workgroup" "main" {
  name = "datalake_workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.bucket_id}/athena-results/"
    }
  }
}

resource "aws_glue_catalog_table" "tenant_data" {
  name          = "tenant_data"
  database_name = aws_glue_catalog_database.datalake_db.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "parquet"
  }

  storage_descriptor {
    location      = "s3://${var.bucket_id}/curated"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    ser_de_info {
      name                  = "parquet"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    columns {
      name = "id"
      type = "int"
    }
    columns {
      name = "name"
      type = "string"
    }
  }

  partition_keys {
    name = "tenant_id"
    type = "string"
  }
}

# 1. Get the Account ID
#data "aws_caller_identity" "current" {}


resource "aws_iam_role" "tenant_viewer" {
  name = "DataLakeTenantViewer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "athena.amazonaws.com" }
    }]
  })
}


resource "aws_lakeformation_data_cells_filter" "tenant_alpha_filter" {
  table_data {
    table_catalog_id = data.aws_caller_identity.current.account_id
    database_name    = aws_glue_catalog_database.datalake_db.name
    table_name       = aws_glue_catalog_table.tenant_data.name
    name             = "tenant_alpha_only"

    row_filter {
      filter_expression = "tenant_id = 'tenant_alpha'"
    }

    column_wildcard {
      excluded_column_names = []
    }
  }
}

resource "aws_lakeformation_permissions" "test_tenant_alpha" {
  principal   = aws_iam_role.tenant_viewer.arn
  permissions = ["SELECT"]

  data_cells_filter {
    table_catalog_id = data.aws_caller_identity.current.account_id
    database_name    = aws_glue_catalog_database.datalake_db.name
    table_name       = aws_glue_catalog_table.tenant_data.name
    name             = "tenant_alpha_only"
  }

  depends_on = [aws_lakeformation_data_cells_filter.tenant_alpha_filter]
}