###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ClientMergeInput < BaseInputObject
    argument :client_ids, [ID], required: true
  end
end
