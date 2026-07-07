###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::OutgoingReferralPostingInput < BaseInputObject
    argument :project_id, ID, required: false
    argument :enrollment_id, ID, required: false
    argument :unit_type_id, ID, required: false
    argument :note, String, required: false
  end
end
