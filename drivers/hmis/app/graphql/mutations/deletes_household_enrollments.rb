###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  module DeletesHouseholdEnrollments
    # Destroys the household of the provided HoH enrollment
    # Safe to call from within or outside an existing transaction: always wraps in
    # a transaction, which joins an outer transaction if one is already open.
    def destroy_household!(hoh_enrollment:)
      raise 'expected HoH' unless hoh_enrollment.head_of_household?
      raise 'missing household ID' unless hoh_enrollment.household_id.present?

      ensure_can_delete_household!(enrollment: hoh_enrollment)

      Hmis::Hud::Enrollment.transaction do
        hoh_enrollment.household_members.each(&:destroy!)
      end
    end

    private

    # Ensure user has permission to delete ALL hhm enrollments.
    # This will raise if we hit an edge case (bad data quality, disallowed in HMIS frontend)
    # where the HoH enrollment is WIP and other members are not, for users who are only allowed to delete WIP enrollments.
    def ensure_can_delete_household!(enrollment:)
      enrollment.household_members.each do |hhm_enrollment|
        access_denied! unless policy_for(hhm_enrollment, policy_type: :hmis_enrollment).can_delete?
      end
    end
  end
end
