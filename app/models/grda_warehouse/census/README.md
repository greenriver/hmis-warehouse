# Census Report Documentation

The term **"Census"** in this context refers to a custom reporting concept specific to this Open Path. It is **not** related to the US Census or any HUD-defined census or reporting requirements.

## What is the Census Report?

The Census system tracks nightly client and bed counts by project and population type (veterans, children, adults). Data is periodically rebuilt from service and inventory records for use in reports and charts.

## Key components:
- `CensusBuilder`: Populates the nightly_census_by_projects table
- `ByProject`: ActiveRecord model for querying census data
- `CensusReport`: Generates reports from the census data

For implementation details, see the code in this directory.

## Where is the Data Used?

- Drives charts and analytics for the "Census" report and the project page in the application.
- Supports warehouse report
