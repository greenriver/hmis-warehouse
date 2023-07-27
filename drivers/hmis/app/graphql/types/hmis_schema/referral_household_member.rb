###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ReferralHouseholdMember < Types::BaseObject
    description 'HUD Client within a Referral Household'
    field :id, ID, null: false
    field :relationship_to_ho_h, Types::HmisSchema::Enums::Hud::RelationshipToHoH, null: false, method: :relationship_to_hoh_before_type_cast
    field :client, HmisSchema::Client, null: false
    field :open_enrollment_summary, [HmisSchema::EnrollmentSummary], null: false

    def open_enrollment_summary
      object.client.enrollments.where.not(id: object.id).not_exited.summary_viewable_by(current_user)
    end
  end
end
