# Project Data Quality Report Calculations

## Overview

### Enrolled Clients

The number of enrollments for the project during the reporting period.

### Enrolled Households

The number of enrollments with `RelationshipToHoH` blank or '1' for the project during the reporting period.

### Active Clients

The number of enrollments for the project during the reporting period for entry/exit projects, or with service during the reporting period for night-by-night projects.

### Active Households

The number of enrollments with `RelationshipToHoH` blank or '1' for the project during the reporting period for entry/exit projects, or with service during the reporting period for night-by-night projects.

### Entering Clients

The number of enrollments for the project during the reporting period with an `EntryDate` during the reporting period.

### Entering Households

The number of enrollments for the project during the reporting period with `RelationshipToHoH` blank or '1', and with the `EntryDate` during the reporting period.

### Exiting Clients

The number of enrollments for the project during the reporting period with an `ExitDate` during the reporting period.

### Exiting Households

The number of enrollments for the project during the reporting period with `RelationshipToHoH` blank or '1', and with an exit record and the `ExitDate` during the reporting period.

## Bed Utilization

*NOTE:* Calculated from computed service records and does not include extrapolated Street Outreach data.

### Bed Inventory

The sum of the `BedInventory` fields for project inventories with inventory covering any part of the reporting period.

### Average Daily / Nightly Clients

The sum of the number of service entries on each day of the reporting period divided by the number of days.

### Average Bed Utilization

The average daily clients from above divided by the bed inventory from above.

### Graph

The sum of the number of service entries on each day of the reporting period.

## Unit Utilization

*NOTE:* Calculated from computed service records and does not include extrapolated Street Outreach data.

### Unit Inventory

The sum of the `UnitInventory` fields for project inventories with inventory covering any part of the reporting period.

### Average Daily / Nightly Clients

The sum of the number of service entries for heads of households on each day of the reporting period divided by the number of days.

### Average Unit Utilization

The average daily clients from above divided by the unit inventory from above.

### Graph

The sum of the number of service entries for heads of households on each day of the reporting period.

## Completeness

Each attribute is assigned to the first matching bucket in the order:
refused, not collected, missing, partial, complete.

### Completeness Percentage

The total number of metrics (the number of enrollments * the number of
completeness metrics) minus he number of metrics not marked _complete_
divided by the total number of metrics.

### Name

Computed for all enrollments using `NameDataQuality`.
Name is missing if the `FirstName` or `LastName` are blank.

### SSN

Computed for all enrollments using `SSNDataQuality`.
SSN is missing if it is blank, or is not a valid SSN:

- Cannot contain a non-numeric character
- Must be 9 digits long
- First three digits cannot be "000," "666," or in the 900 series
- The second group / 5th and 6th digits cannot be "00"
- The third group / last four digits cannot be "0000"
- Cannot be repetitive (e.g. "333333333")
- Cannot be one of '219099999', '078051120', or '123456789'

### DOB

Computed for all enrollments using `DOBDataQuality`.
DOB is missing if it is:

- Blank
- Incomplete (which implies that DOB's will never be reported as partial)
- Is before Jan 1, 1915
- Is after the `DateCreated` of the associated enrollment
- If the client is an adult on the on the date the report was generated or head of household, and the DOB is on or after the `EntryDate`

### Gender

Computed for all enrollments using `Gender`.
Gender is missing if it is blank.

### Veteran Status

Only computed for enrollments using `VeteranStatus` if the client is an adult on the `EntryDate`.
Veteran Status is missing if it is blank.

### Ethnicity

Computed for all enrollments using `Ethnicity`.
Ethnicity is missing if it is blank.

### Race

Computed for all enrollments using `RaceNone`.
Race is missing if `RaceNone`, `AmIndAKNative`, `Asian`, `BlackAfAmerican`, `NativeHIPacific`, and `White`
are all blank.

### Disabling Condition

Computed for enrollments using `DisablingCondition` if the client is an adult on the on the date the report was generated.
Disabling Condition is missing if `DisablingCondition` is blank, or if it is '0', and if any of the most
recent disability responses are '1'.

### Prior Living Situation

Computed for enrollments where the client is either the head of household, or an adult on the on the date the report was generated, using`LivingSituation`.
Prior Living Situation is missing if it is blank.


### Destination

Computed for enrollments with an exit and the client is either the head of household, or an adult on the on the date the report was generated, using `Destination`.
Destination is missing if it is blank.

### Income At Entry

Computed for enrollments where the client is either the head of household, or an adult on the on the date the report was generated using `IncomeFromAnySource`.
Income At Entry is missing if there is no income benefit at entry.

### Income Annual Assessment

Computed for enrollments where the client is either the head of household or an adult on the on the date the report was generated, and have been enrolled for more than one year since the report end date.
Income Annual Assessment is missing if there is no annual assessment for the enrollment before the report end date.


### Income At Exit

Computed for enrollments where the client is either the head of household or an adult on the on the date the report was generated, and exited during the reporting period.
Income At Entry is missing if there is no income benefit at exit.

## Timeliness

### Time To Enter

The number of days between the `EntryDate` and the `DateCreated` for each enrollment divided by the number of enrollments.

### Time To Exit

The number of days between the `EntryDate` and the `DateCreated` for each exit divided by the number of exits.

## Outcomes

### Time In Project

The time-in-project for an enrollment is the number of service days through the end of the reporting period for a night-by-night project, otherwise, the number of days enrolled if the enrollment has an exit during the reporting period, or the number of days enrolled through the last day of the reporting period for an entry/exit
program.

#### Average Time in Project

The sum of the times-in-project as described above divided by the number of enrollments in the reporting period.

#### Percent in Project Over One Year

The number of enrollments with 356+ days of service as described above, divided by the number of enrollments in the reporting period.

#### Chart

Counts of the number of enrollments in each group, calculated as described above.

### Percentage of Clients Increasing or Retaining Income

Computed for clients that were adults at `EntryDate` or head of household, using the last two income assessments at or before the report end for each enrollment with _at least_ two.

Non-employment cash income is defined as any of unemployment, SSI, SSDI, VA or private disability, workers comp, TANF, GA, Social Security retirement, pensions, child support, alimony, or other unclassified income.

### Percentage of Clients With No Income

Computed for clients that were adults at `EntryDate` or head of household, using the most recent available income assessment at or before the report end.

Non-employment cash income is defined as any of unemployment, SSI, SSDI, VA or private disability, workers comp, TANF, GA, Social Security retirement, pensions, child support, alimony, or other unclassified income.

### Exiting to PH / Percentage of Clients Exiting to Permanent Housing

The number of enrollments with an exit in the reporting period with a `Destination` of one of the HUD-defined permanent housing destinations divided by the number enrollments with an exit in the reporting period.
