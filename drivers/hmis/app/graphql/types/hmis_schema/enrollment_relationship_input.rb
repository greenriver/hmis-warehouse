###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::EnrollmentRelationshipInput < BaseInputObject
    argument :enrollment_id, ID, required: true
    argument :relationship_to_hoh, Types::HmisSchema::Enums::Hud::RelationshipToHoH, required: true
  end
end
