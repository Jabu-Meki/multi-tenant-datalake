resource "aws_glue_catalog_database" "datalake_db" {
  name = "multi_tenant_datalake_${var.environment}"
}

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
