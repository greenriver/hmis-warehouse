## HudLsa README

Generates the Longitudinal Systems Analysis Report (LSA) by exporting the data to an external MSSQL Server, using the HUD [Sample Code](https://github.com/HMIS/LSASampleCode), and then importing the results into the common HUD Report structure.

### Running the LSA

The LSA spins up a SQL server instance on RDS and needs appropriate permissions to access it.  You may find you need to provide AWS credentials to get the LSA working.  Something like the following may be helpful.

```
aws-vault exec openpath -- docker compose up -d
```

# Sample Files and Testing
Sample source and result files for the LSA are provided by HUD as part of the [LSA Sample Code ](https://github.com/HMIS/LSASampleCode).

At the time of this writing (FY2024) you can download the [sample output here](https://github.com/HMIS/LSASampleCode/blob/master/Sample%20Data/Sample%20LSA%20Output.zip) and the [sample input here](https://github.com/HMIS/LSASampleCode/blob/master/Sample%20Data/Sample%20HMIS%20Data.zip).  Once downloaded, expand the input into `drivers/hud_lsa/spec/fixtures/files/lsa/fy2024/sample_hmis_export` and the output into `drivers/hud_lsa/spec/fixtures/files/lsa/fy2024/sample_results`.

Tests can be run by re-using a previous run:
```
r = HudLsa::Generators::Fy2024::Lsa.last
r.test = true
# r.destroy_rds = false # uncomment to keep the RDS server alive after completion
r.run!
```

By setting the `test` flag, it will ignore the export process and use the supplied files.

You can compare the test results to the sample results with the provided LSA Comparison Tool.  First, download and expand the results from the test run to `var/lsa/generated`.

```
checker = HudLsa::Generators::Fy2024::LsaComparisonTool.new('drivers/hud_lsa/spec/fixtures/files/lsa/fy2024/sample_results', 'var/lsa/generated')
checker.compare
```
