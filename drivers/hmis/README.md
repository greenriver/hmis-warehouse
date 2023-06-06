## HMIS Driver

This driver contains all the backend logic for supporting the [HMIS Frontend](https://github.com/greenriver/hmis-frontend).

To enable locally:
```
ENABLE_HMIS_API=true
HMIS_HOSTNAME=hmis.dev.test
```

### New Deployment Checklist

Some things need to be done manually for a new deployment:

* Create the HMIS Data Source
* Create an HMIS Administrator role
* Configure permissions in the warehouse
* Set up File Tags in the warehouse
* Create any UnitTypes
* Create any CustomServiceTypes and categories
* Create any CustomDataElementDefinitions
* Set up any RemoteCredentials
* Enable any InboundApiConfigurations
* Create a GrdaWarehouse::Theme