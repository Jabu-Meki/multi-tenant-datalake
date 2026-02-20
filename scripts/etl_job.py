import json
import urllib.parse
import boto3

def handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']

    raw_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])

    path_parts = raw_key.split('/')

    tenant_id = path_parts[1]
    file_name = path_parts[-1]

    print(f"--- ETL PROCESS STARTING ---")
    print(f"Tenant detected: {tenant_id}")
    print(f"Processing file: {file_name}")
    print(f"Full S3 Path: s3://{bucket}/{raw_key}")

    return{
        'statusCode': 200,
        'body' : json.dumps({
            "message": "Detection successful",
            "tenant": tenant_id,
            "file": file_name
        })
    }