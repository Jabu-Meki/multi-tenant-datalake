# Multi-Tenant S3 Data Lake with Row-Level Security

## Project Overview
This repository contains an enterprise-grade, serverless data lake architecture deployed via Terraform. The solution implements a Medallion Architecture (Raw-to-Curated) to process and store data for multiple isolated organizations (tenants) within a single AWS account. The project emphasizes data governance, cost optimization, and fine-grained access control using AWS Lake Formation.

## Security Disclaimer
**IMPORTANT:** This repository is intended for demonstration and educational purposes. While it implements several security best practices (such as S3 Public Access Blocks and Row-Level Security), it is not a "production-ready" hardened environment. Before deploying this architecture in a live production setting, the following additional security measures should be conducted:
*   **KMS Integration:** Replace standard AES256 encryption with Customer Master Keys (CMK) managed via AWS KMS for granular audit logging.
*   **Network Isolation:** Deploy Lambda functions and Athena workgroups within a Private VPC with S3 VPC Endpoints to ensure data never traverses the public internet.
*   **Advanced IAM Audit:** Conduct a full IAM Access Analyzer review to further restrict roles to the absolute minimum required permissions (Least Privilege).
*   **Logging and Monitoring:** Enable S3 Server Access Logging and AWS CloudTrail Data Events for a complete audit trail of all data access.

## Core Architecture and Engineering Choices

### 1. Dynamic Multi-Tenancy
The system utilizes a prefix-based isolation strategy within S3. Tenants are dynamically identified by the infrastructure through their S3 path (`raw/tenant_id/`). This allows the system to scale to an unlimited number of tenants without requiring manual infrastructure changes or unique IAM users for every new onboarding.

### 2. Automated Medallion ETL Pipeline
Data follows a structured lifecycle to ensure quality and performance:
*   **Raw Zone (Bronze):** Ingests original CSV files. 
*   **Processing Layer:** An AWS Lambda function, triggered by S3 Event Notifications, performs the transformation.
*   **Curated Zone (Silver):** Data is converted into Apache Parquet format and stored using Hive-style partitioning (`tenant_id=name/`).

### 3. Cost Optimization and Performance
*   **Columnar Storage:** By converting CSV to Parquet, query costs in Athena are reduced by up to 90% as the engine only scans the specific columns required for the query.
*   **Partition Pruning:** Hive-style partitioning ensures that queries filtered by `tenant_id` skip unrelated data prefixes entirely.
*   **Serverless Compute:** The use of AWS Lambda (leveraging the AWS DataWrangler layer) ensures zero idle costs, as compute resources only exist during the transformation window.

### 4. Data Governance and Security
*   **Row-Level Security (RLS):** Implemented via AWS Lake Formation Data Cells Filters. This ensures that even when multiple tenants reside in the same Glue table, a tenant-specific role is physically restricted to viewing only its own rows.
*   **Least Privilege IAM:** Dedicated roles are provisioned for the ETL process and the end-user query layer, minimizing the blast radius of any single identity.

## Technical Stack
*   **Infrastructure as Code:** Terraform
*   **Cloud Provider:** Amazon Web Services (AWS)
*   **Storage:** Amazon S3
*   **Compute:** AWS Lambda (Python 3.9)
*   **ETL Libraries:** AWS DataWrangler, Pandas, Boto3
*   **Data Catalog:** AWS Glue
*   **Query Engine:** AWS Athena
*   **Security & Governance:** AWS Lake Formation, IAM

## Project Structure
```text
├── environments/
│   └── dev/                # Primary deployment environment and provider configuration
├── modules/
│   ├── storage/            # S3 bucket provisioning, lifecycle policies, and encryption
│   ├── processing/         # Lambda ETL logic, S3 event triggers, and IAM execution roles
│   └── governance/         # Glue Database, Athena Workgroups, and Lake Formation RLS filters
├── scripts/
│   └── etl_job.py          # Python handler for CSV-to-Parquet transformation and partitioning
└── README.md
```

## Deployment Instructions

### Prerequisites
*   Terraform installed locally.
*   AWS CLI configured with appropriate administrative credentials.
*   An existing AWS account.

### Execution
1.  Navigate to the environment directory:
    ```bash
    cd environments/dev/
    ```
2.  Initialize the Terraform workspace:
    ```bash
    terraform init
    ```
3.  Review the infrastructure plan:
    ```bash
    terraform plan
    ```
4.  Deploy the architecture:
    ```bash
    terraform apply
    ```

## Operational Workflow (Testing)
1.  **Data Ingestion:** Upload a sample CSV file to the S3 bucket under the path `raw/tenant_alpha/sample_data.csv`.
2.  **Automated Processing:** Monitor AWS CloudWatch logs for the `/aws/lambda/multi-tenant-etl-processor` group to verify successful transformation.
3.  **Partition Registration:** In the AWS Athena Console, execute the following command to update the metadata:
    ```sql
    MSCK REPAIR TABLE multi_tenant_datalake_dev.tenant_data;
    ```
4.  **Data Validation:** Execute a SQL query to verify tenant isolation and data integrity:
    ```sql
    SELECT * FROM multi_tenant_datalake_dev.tenant_data WHERE tenant_id = 'tenant_alpha';
    ```

## Security Verification
The Lake Formation configuration can be verified in the AWS Console under **Data Filters**. The `tenant_alpha_only` filter is automatically mapped to the `DataLakeTenantViewer` role, providing a template for how enterprise organizations enforce strict data privacy across shared datasets.