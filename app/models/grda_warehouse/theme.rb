###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Example for testing:
# GrdaWarehouse::Theme.create!(
#   client: 'myclient', # should match ENV['CLIENT']
#   hmis_value: {
#     palette: {
#       primary: {
#         main: '#0D394E',
#       },
#       secondary: {
#         main: '#357650',
#       },
#     },
#   }
# )
module GrdaWarehouse
  class Theme < GrdaWarehouseBase
  end
end
