# Open Path HMIS Warehouse [![Actions Status](https://github.com/greenriver/hmis-warehouse/workflows/Bundle%20Audit%20and%20Brakeman/badge.svg)](https://github.com/greenriver/hmis-warehouse/actions)

Open Path is an open-source platform for managing homeless services. It helps Continuums of Care (CoCs) collect client data and meet the reporting requirements of the U.S. Department of Housing and Urban Development (HUD). An installation can serve a single organization or a multi-state region.

This repository holds the core application. It covers:

- **HMIS data entry:** users record clients, enrollments, and services. A Homeless Management Information System (HMIS) is a system for collecting client-level data on the housing and services provided to people experiencing homelessness.
- **Data warehousing:** loads HMIS data from other vendors' systems and matches records for the same person into one client record.
- **Coordinated Entry:** assesses and prioritizes people for housing and services.
- **Federal reporting:** produces reports defined by HUD and other federal agencies, including:
  - the CoC Annual Performance Report (APR) and Coordinated Entry APR
  - the Consolidated Annual Performance and Evaluation Reports (CAPERs) for the ESG and HOPWA programs
  - System Performance Measures (SPM) and the Longitudinal Systems Analysis (LSA)
  - the Point-in-Time count (PIT) and Housing Inventory Count (HIC)
  - the PATH Annual Report
  - the HMIS Data Quality Report
- **Data exchange:** imports and exports data in the HUD HMIS CSV format.

## Origin

The project was started by the City of Boston's Department of Neighborhood Development. The City of Boston chose to release it as open source under the GPL. Our goal is to let Boston's investment help other municipalities and organizations, and to keep improving the software together with the communities that use it.

## Related projects

- [Open Path HMIS](https://github.com/greenriver/hmis-frontend): the web application for HMIS data entry and Coordinated Entry. This repository provides its API.
- [Open Path CAS](https://github.com/greenriver/boston-cas): matches clients to available housing.

## Third-party services

Depending on how it is configured, an installation may use:

- **Amazon Web Services (AWS):** hosting, file storage, email, and notifications. [Terms](https://aws.amazon.com/service-terms/)
- **Apache Superset:** analytics dashboards. [superset.apache.org](https://superset.apache.org)
- **Login providers:** single sign-on through Keycloak or an organization's own provider, such as [Okta](https://www.okta.com).
- **Sentry:** error and job monitoring. [sentry.io](https://sentry.io)
- **Slack:** notifications. [slack.com](https://slack.com)
- **TalentLMS:** checks that users have completed required training before they can see data. [Terms](https://www.talentlms.com/terms)
- **Upstream HMIS vendors:** loads data from Eccovia ClientTrack and Social Solutions ETO, set up per installation.
- **State Medicaid agencies:** checks homelessness status with a state Medicaid agency, set up per installation.
- **US Census:** population data used for comparison with HMIS data. [Terms](https://www.census.gov/data/developers/about/terms-of-service.html)
- **Nominatim (OpenStreetMap).** [Usage policy](https://operations.osmfoundation.org/policies/nominatim/)

## License

```text
Copyright © 2017 Green River Data Group, Inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
```

A copy of the license is available in [LICENSE.md](https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md)

## For developers

Issues and pull requests are welcome.

- [Developer setup](docs/developer/setup.md)
- [Architecture overview](docs/architecture/README.md)
- [Feature documentation](docs/features/)
