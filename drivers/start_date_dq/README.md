# "Date Homelessness Started" Data Quality Report

## Overview
This data quality report analyzes the relationship between a client's self-reported date homelessness started (DateToStreetESSH) and their program entry date (EntryDate) for records in the live HMIS data. The report helps identify potential data quality issues and patterns in how homelessness history is being recorded.

## Purpose
- Identify discrepancies between when clients report becoming homeless and when they enter programs
- Evaluate data quality for the DateToStreetESSH field, which is critical for chronic homelessness determination
- Monitor how long clients are homeless before accessing services
- Support CoC reporting needs around length of homelessness prior to intervention

## Key Features
- Calculates the number of days between DateToStreetESSH and EntryDate
- Categorizes these time periods into meaningful ranges (<0 days, 0-30 days, 31-90 days, 91-180 days, 181+ days)
- Provides additional context including exit dates and project types
- Supports filtering by date range, project type, CoC codes, and other standard parameters

## Technical Implementation
The report is implemented as a Ruby module within the HMIS data warehouse and uses the standard filtering infrastructure to allow customization of the report parameters.
