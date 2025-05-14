# HUD LSA Report Generator

This module generates HUD LSA (Longitudinal System Analysis) reports by exporting data to an external MSSQL Server, using the HUD [Sample Code](https://github.com/HMIS/LSASampleCode), and importing results into the common HUD Report structure.

## Architecture

The LSA report generation process runs as a background job using Delayed Job. Each report run:

1. Creates a temporary RDS SQL Server instance (or uses a static instance if configured)
2. Creates a temporary database for the report
3. Exports HMIS data to CSV
4. Imports the data into SQL Server
5. Runs LSA queries
6. Exports results
7. Cleans up temporary resources

### Key Components

- `HudLsa::Generators::Fy2024::Lsa`: Main report generator class
- `HudLsa::RunReportJob`: Background job handler
- `RdsConcern`: Manages RDS instance lifecycle
- `SqlServerBase`: Handles SQL Server connections

### Thread Safety

⚠️ **Not Thread Safe**

The current implementation is not thread-safe due to:

- Use of class-level variables (`cattr_accessor`) in `SqlServerBase`
- Shared mutable state for RDS instance and connection management
- No synchronization mechanisms for concurrent access

While the system currently runs in a single-threaded context via Delayed Job, care should be taken when:
- Modifying the code to support concurrent execution
- Running multiple reports simultaneously

## RDS Instance Management

### Dynamic vs Static RDS

The system supports two modes of operation:

1. **Dynamic RDS** (default):
   - Creates a new RDS instance for each report
   - Instance is destroyed after report completion
   - Instance name format: `{client}-{env}-LSA-{report_id}`

2. **Static RDS**:
   - Uses a pre-configured RDS instance
   - Configured via `LSA_DB_HOST` environment variable
   - Database is dropped after report completion

### S3 Integration

For faster data imports, the system can use AWS RDS S3 integration:

1. Files are uploaded to S3
2. RDS instance is configured with S3 access
3. Data is imported directly from S3 to RDS
4. Temporary files are cleaned up

Configure via:
```ruby
GrdaWarehouse::Config.set(:rds_s3_integration_role_arn, 'arn:aws:iam::...')
```

## Report Generation Process

1. **Preflight Check**:
   - Validates project data completeness
   - Prevents report generation if critical data is missing

2. **Data Export**:
   - Exports HMIS data to CSV format
   - Handles data cleaning and standardization

3. **RDS Setup**:
   - Creates/connects to RDS instance
   - Creates temporary database
   - Sets up table structure

4. **Data Import**:
   - Imports HMIS data into SQL Server
   - Uses bulk insert for performance
   - Handles data type conversions
   - Fixes some known data quality issues with obvious fixes

5. **LSA Processing**:
   - Runs LSA queries in sequence
   - Updates progress tracking
   - Generates summary results

6. **Result Export**:
   - Exports results to CSV
   - Creates ZIP archive
   - Attaches files to report

7. **Cleanup**:
   - Drops temporary database
   - Terminates RDS instance (if dynamic)
   - Removes temporary files

## Configuration

### Environment Variables

- `RDS_AWS_ACCESS_KEY_ID`: AWS credentials for RDS management
- `NO_LSA_RDS`: Disable RDS functionality
- `LSA_DB_HOST`: Use static RDS instance
- `DJ_LONG_QUEUE_NAME`: Delayed Job queue name

### AWS Requirements

- IAM role with RDS management permissions
- S3 bucket for temporary file storage
- IAM role for RDS S3 integration (optional)

## Running the LSA

The LSA spins up a SQL server instance on RDS and needs appropriate permissions to access it. You may need to provide AWS credentials to get the LSA working:

```bash
aws-vault exec openpath -- docker compose up -d
```

## Testing and Sample Files

Sample source and result files for the LSA are provided by HUD as part of the [LSA Sample Code](https://github.com/HMIS/LSASampleCode).

For FY2024, you can download:
- [Sample Output](https://github.com/HMIS/LSASampleCode/blob/master/Sample%20Data/Sample%20LSA%20Output.zip)
- [Sample Input](https://github.com/HMIS/LSASampleCode/blob/master/Sample%20Data/Sample%20HMIS%20Data.zip)

### Setting Up Sample Data

1. Expand the input into `drivers/hud_lsa/spec/fixtures/files/lsa/fy2024/sample_hmis_export`
2. Expand the output into `drivers/hud_lsa/spec/fixtures/files/lsa/fy2024/sample_results`

### Running Tests

Tests can be run by re-using a previous run:

```ruby
report = HudLsa::Generators::Fy2024::Lsa.last
report.test = true
# r.test_type = :hic # to test the HIC version
# r.destroy_rds = false # uncomment to keep the RDS server alive after completion
report.run!
```

By setting the `test` flag, it will ignore the export process and use the supplied files.

### Comparing Results

You can compare the test results to the sample results with the provided LSA Comparison Tool:

1. Download and expand the results from the test run to `var/lsa/generated`
2. Run the comparison:
```ruby
checker = HudLsa::Generators::Fy2024::LsaComparisonTool.new(
  'drivers/hud_lsa/spec/fixtures/files/lsa/fy2024/sample_results',
  'var/lsa/generated'
)
checker.compare
```
