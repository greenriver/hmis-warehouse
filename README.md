# Boston HMIS Warehouse [![Actions Status](https://github.com/greenriver/hmis-warehouse/workflows/Audit%20and%20Test/badge.svg)](https://github.com/greenriver/hmis-warehouse/actions)

## Introduction
The HMIS Warehouse project was initiated by the City of Boston's Department of Neighborhood Development to gather data from across various HMIS installations, produce aggregated reports, and supply de-duplicated client information to the [Boston CAS](https://github.com/greenriver/boston-cas) system for Coordinated Access to housing.

The Warehouse is capable if ingesting standard HUD HMIS CSV files as well as data via the Social Solutions ETO API.

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

Looking ahead, we see the Warehouse codebase serving as a foundation for all communities that report to the department of Housing and Urban Development, or have a need to aggregate and de-duplicate homeless client data from across various systems.  To our knowledge, this is the only open source, freely available implementation of many HUD reports.

## Application Design

The application is designed around the [HUD Data Standards](https://www.hudexchange.info/programs/hmis/hmis-data-and-technical-standards/) and the data structure is based on the [HMIS Logical Model](http://www.hudhdx.info/VendorResources.aspx)

The application is written primarily in [Ruby on Rails](http://rubyonrails.org) and we use [RVM](https://rvm.io/) to select a ruby version. Other ruby version managers should work fine, as would manually installing the ruby version mentioned in the `.ruby-version`

The application uses [postgres](https://www.postgresql.org/) for application data storage and [Microsoft SQL Server](https://www.microsoft.com/en-us/sql-server/) or postgres for the warehouse data.

We've developed locally on OSX using [homebrew](http://brew.sh/) and deployed to Ubuntu 16.04 using `apt` for dependencies.

## Third-party Available Integrations

- Amazon Web Services provides cloud hosting services. Configured via various env variables.  Services used outside of hosting are SNS, SES, S3, and Glacier.
  Terms: https://aws.amazon.com/service-terms/

- ETO API and QaaWS - HMIS and ancillary data can be fetched via various endpoints.  OpenPath accesses Social Solutions ETO in a variety of ways, custom configured for each installation. [https://www.socialsolutions.com/software/eto/]

- Nominatim - an API service for open street map data [https://nominatim.openstreetmap.org]. Only zip codes are sent to the service, used to display a map on client dashboards of last permanent destinations.
  Terms: https://operations.osmfoundation.org/policies/nominatim/

- NOAA Weather - Weather for individual dates and one location per installation are fetched on-demand from NOAA [https://www.ncdc.noaa.gov/cdo-web/webservices/v2]

- Exceptions can be sent to a slack channel. Configuration is done via env `EXCEPTION_WEBHOOK*`

- MassHealth - X12 data transfer via api, configurable per installation

- HelloSign - for signing of health careplans electronically. [https://www.hellosign.com/terms]

- OKTA - for single sign-on. [https://www.okta.com]

- US Census - for comparing HMIS and population data. [https://www.census.gov/data/developers/about/terms-of-service.html]

- Talent LMS - for training. [https://www.talentlms.com/terms]

### Developer Prerequisites

If you are unfamiliar with contributing to open source projects on Github you may first want to read some of the guides at:  https://guides.github.com/

There is a simple script to setup a development environment in `bin/setup`. To make it run smoothly you should have:

* A running Ruby 2.3+ environment with bundler 1.11+ installed.
* A local install of postgresql 9.5+ allowing your user to create new databases.
* A local install of redis for caching. redis-server should be running on the default port
* libmagic

Once these are in place, `bin/setup` should:

* Install all ruby dependencies.
* Create initial copies of configuration files.
* Create an initial database and seed it with reference data and a randomly generated admin user.

If all goes well you should then be able to run `bin/rails server` and open the Warehouse in your system at http://localhost:3000 using the email/password created during `bin/setup`. If not, read `bin/setup` to figure out what went wrong and fix it.

Hack on your version as you see fit and if you have questions or want to contribute open an issue on github.

# Developer Notes

We use the following common rails gems and conventions:

* `haml` for view templating
* `bootstrap` for base styles and layout
* `sass` for custom-css
* `simple_form` for forms
* `pagy` for pagination
* `brakeman` for basic security scanning.
* `rack-mini-profiler` to make sure pages are fast. Ideally <200ms
* helpers need to be explictly loaded in controllers. i.e. we have `config.action_controller.include_all_helpers = false` set
* `bin/rake generate controller ... ` doesn't make fixures and they are disabled in test_helper. We don't use them and instead seed data in test or let test create their own data however they need to.
* it also doesn't make helper or asset stubs, make them by hand if you need one. See `config/application.rb` for details.

# Multiple databases

The project reads/writes from several different databases. We keep track of these different environments by setting up parallel db configs and structures for each database. Health care data is configured in config/database_health.yml and database resources are in db/health. Warehouse data is configured in config/database_warehouse.yml and resources are in db/warehouse. When running migrations, use the custom generators.

App migrations can be created with:

```
rails generate migration foo
```
and run with
```
rake db:migrate
```
Warehouse migrations can be created with:
```
rails generate warehouse_migration foo
```
and run with
```
rake warehouse:db:migrate
```

Health migrations can be created with

```
rails generate health_migration foo
```
and run with
```
rake health:db:migrate
```

# How to Create a New Report

Follow these steps to create a new custom report.

1. Generate scaffolding for a new [Rails Driver](https://github.com/degica/rails_drivers):
    ```bash
    rails g driver custom_new_report_name
    ```
2. Add the relevant routes, controller, and view to the new Driver. See other examples for how they should be namespaced.
3. Add your new report to the `report_list` in the `GrdaWarehouse::WarehouseReports::ReportDefinition` model. Make sure to wrap it in a check to see whether the driver is loaded. See [ReportDefinition](https://github.com/greenriver/hmis-warehouse/blob/production/app/models/grda_warehouse/warehouse_reports/report_definition.rb) for examples.
4. Finally, run `rails db:seed` to populate the database with your new report definition. Alternatively, you can run the two relevant steps individually:
    ```ruby
    # Generates a new ReportDefinition
    GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
    # Adds the report to the "all reports" group
    AccessGroup.maintain_system_groups
    ```
