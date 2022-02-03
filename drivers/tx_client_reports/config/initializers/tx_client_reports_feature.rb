###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# TxClientReports driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:tc_client_data_report)
#
# use with caution!
RailsDrivers.loaded << :tx_client_reports
