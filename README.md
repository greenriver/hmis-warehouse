# Open Path HMIS Warehouse [![Actions Status](https://github.com/greenriver/hmis-warehouse/workflows/Bundle%20Audit%20and%20Brakeman/badge.svg)](https://github.com/greenriver/hmis-warehouse/actions)

## Table of Contents
1. [Introduction](#introduction)
2. [Vision](#vision)
3. [Application Design](#application-design)
4. [Other Open Path Applications](#other-open-path-applications)
5. [Third-Party Integrations](#third-party-integrations)
6. [Developer Documentation](#developer-documentation)

## Introduction

The HMIS Warehouse project was initiated by the City of Boston's Department of Neighborhood Development to gather data from across various HMIS installations, produce aggregated reports, and supply de-duplicated client information to the [Boston CAS](https://github.com/greenriver/boston-cas) system for Coordinated Access to housing.

At its core the Warehouse ingests standard HUD HMIS CSV files, de duplicates clients across HMIS data sources, and aggregates data associated with HMIS clients from additional sources.

```a
Copyright © 2017 Green River Data Analysis, LLC

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

## Vision

The City of Boston made a conscientious choice to release this project into the open source under a GPL. Our goal is to promote this opportunity, allowing Boston's investment to assist other municipalities and organizations, and realize the vision of a tool under continuous, collaborative improvement helping communities nationwide.

Looking ahead, we see the Warehouse codebase serving as a foundation for all communities that report to the department of Housing and Urban Development, or have a need to aggregate and de-duplicate homeless client data from across various systems.

## Application Design

The application is designed around the [HUD Data Standards](https://www.hudexchange.info/programs/hmis/hmis-data-and-technical-standards/) and the data structure is based on the [HMIS Logical Model](https://github.com/hmis-interop/logical-model)

The application is written primarily in [Ruby on Rails](http://rubyonrails.org), and uses [postgres](https://www.postgresql.org/) for data storage.

## Other Open Path Applications
Open Path is a suite of open-source HMIS related applications and includes:
- Open Path Warehouse, found in this repository
- [Open Path HMIS](http://github.com/greenriver/hmis-frontend), a service provider front-end HMIS tightly integrated with the warehouse
- [Open Path CAS](https://github.com/greenriver/boston-cas), a coordinated entry workflow tool for streamlining access to limited housing and other resources.

## Third-Party Integrations
The Open Path Warehouse integrates with a variety of third-party applications and APIs, the following is a high-level list of the more tightly integrated or impactful integrations.

- Amazon Web Services provides cloud hosting services. Services used outside of hosting are SNS, SES, and S3.
  Terms: https://aws.amazon.com/service-terms/

- Apache Superset - Open Path uses Superset to provide rich analytic reporting and data discovery in OP Analytics. [https://superset.apache.org]

- Eccovia ClientTrack REST API - HMIS and ancillary data can be [fetched via specified endpoints](https://apidoc.eccovia.com).  Open Path's access to Eccovia ClientTrack is custom configured for each installation. [https://eccovia.com/clienttrack/]

- ETO API and QaaWS - HMIS and ancillary data can be fetched via various endpoints.  Open Path's access if Social Solutions ETO is custom configured for each installation. [https://www.socialsolutions.com/software/eto/]

- Nominatim - an API service for open street map data [https://nominatim.openstreetmap.org]. Only zip codes are sent to the service, used to display a map on client dashboards of last permanent destinations.
  Terms: https://operations.osmfoundation.org/policies/nominatim/

- NOAA Weather - Weather for individual dates and one location per installation are fetched on-demand from NOAA [https://www.ncdc.noaa.gov/cdo-web/webservices/v2]

- Slack - Exceptions and other notifications can be sent to Slack [https://slack.com].

- MassHealth - Open Path supports integrations with Mass Health for eligibility determination and claim submission via the X12 data transfer over MassHealth's API, configurable per installation

- OKTA - Open Path can be configured with for single sign-on for login and account creation, a native integration with OKTA is included. [https://www.okta.com]

- US Census - Open Path uses US Census data for comparing HMIS and population data. [https://www.census.gov/data/developers/about/terms-of-service.html]

- Talent LMS - Open Path can be configured to require training before granting access to any data within the application via a native integration with Talent LMS. [https://www.talentlms.com/terms]

## Developer Documentation
Anyone is welcome to contribute to the suite of Open Path software by opening an issue or a pull request.  In addition, we love hearing that communities have started using Open Path to help coordinate their efforts to end homelessness.  If you would like to get started with Open Path, check out [the developer setup guide](docs/developer_setup.md).
