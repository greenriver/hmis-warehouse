## ClaimsReporting README

This driver supports reporting on claims data recieved back from health insurance companies.
It will eventually allow reporting on the kinds of claims submitted for Health::QualifyingActivity

### Data Setup

Medical claims data arrives in the format in ClaimsReporting::MedicalClaimsImporter.csv_schema
and can be bulk imported with something like:

```
rails r "ClaimsReporting::MedicalClaimsImporter.reimport_all ENV['FILE']" FILE=...
```

Eventually this data import will be automated similar to other data feeds in the application.
