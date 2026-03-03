import json
import urllib.parse
import boto3
import awswrangler as wr 

def handler(event, context):
    # Get bucket and file path from the S3 event
    bucket = event['Records'][0]['s3']['bucket']['name']
    raw_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])
    
    # 1. Extract Tenant ID (e.g., from raw/tenant_a/data.csv -> tenant_a)
    path_parts = raw_key.split('/')
    tenant_id = path_parts[1]
    file_name = path_parts[-1].split('.')[0] # Get 'data' from 'data.csv'
    
    # 2. Define where the clean file should go
    curated_path = f"s3://{bucket}/curated/{tenant_id}/{file_name}.parquet"
    
    print(f"Transforming: {raw_key} -> {curated_path}")

    try:
        # 3. Read CSV from S3 (Using Wrangler)
        df = wr.s3.read_csv(path=[f"s3://{bucket}/{raw_key}"])
        
        # 4. Write to S3 as Parquet (The "Professional" part)
        wr.s3.to_parquet(
            df=df,
            path=curated_path,
            dataset=True # This helps Athena find it later
        )
        print("Success: File converted and saved to Curated zone.")
        
    except Exception as e:
        print(f"Error: {e}")
        raise e

    return {'statusCode': 200}