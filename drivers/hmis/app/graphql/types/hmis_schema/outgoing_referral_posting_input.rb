###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::OutgoingReferralPostingInput < BaseInputObject
    argument :project_id, ID, required: false
    argument :enrollment_id, ID, required: false
    argument :unit_type_id, ID, required: false
  end
end
