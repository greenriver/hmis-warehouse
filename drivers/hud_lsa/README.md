## HudLsa README

Generates the Longitudinal Systems Analysis Report (LSA) by exporting the data to an external MSSQL Server, using the HUD [Sample Code](https://github.com/HMIS/LSASampleCode), and then importing the results into the common HUD Report structure.

Testing includes the LSA Test Kit that is distributed with the sample code.

### Running the LSA

The LSA spins up a SQL server instance on RDS and needs appropriate permissions to access it.  You may find you need to provide AWS credentials to get the LSA working.  Something like the following may be helpful.

```
aws-vault exec openpath -- docker compose up -d
```
