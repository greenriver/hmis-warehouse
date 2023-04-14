###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::UnitInput < BaseInputObject
    argument :inventory_id, ID
    argument :count, Integer, 'Number of units to create', required: false
    argument :prefix, String, 'Prefix for unit names', required: false
  end
end
