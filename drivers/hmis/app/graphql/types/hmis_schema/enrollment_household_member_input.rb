###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::EnrollmentHouseholdMemberInput < BaseInputObject
    description 'HMIS Enrollment household member input'

    argument :id, ID, required: true
    argument :relationship_to_ho_h, HmisSchema::Enums::Hud::RelationshipToHoH, required: true
  end
end
