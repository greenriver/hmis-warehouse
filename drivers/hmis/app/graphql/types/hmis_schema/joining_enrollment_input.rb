###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::JoiningEnrollmentInput < BaseInputObject
    argument :enrollment_id, ID, required: true
    argument :relationship_to_hoh, Types::HmisSchema::Enums::Hud::RelationshipToHoH, required: true
  end
end
