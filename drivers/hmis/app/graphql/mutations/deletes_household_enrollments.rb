###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  module DeletesHouseholdEnrollments
    # Destroys the given enrollment. If the enrollment belongs to a Head of Household,
    # also destroys all other household members' enrollments to avoid leaving a dangling
    # household without a HoH.
    #
    # Safe to call from within or outside an existing transaction: always wraps in
    # Enrollment.transaction, which joins an outer transaction if one is already open.
    def destroy_enrollment_and_household_if_hoh!(enrollment:)
      enrollments_to_delete = [enrollment]

      if enrollment.head_of_household?
        enrollment.household_members.each do |hhm_enrollment|
          # Check if the user has permission to delete each enrollment. This deals with the hypothetical edge case:
          # If the HoH's enrollment is in-progress, but another HHM has a completed intake (non-WIP),
          # the current user might not have the right permission (can_delete_enrollments) to delete all the enrollments.
          # (This would likely be a data issue from import, since our frontend disallows submitting the HHM intakes before the HoH.)
          access_denied! unless policy_for(hhm_enrollment, policy_type: :hmis_enrollment).can_delete?

          enrollments_to_delete << hhm_enrollment
        end
      end

      Hmis::Hud::Enrollment.transaction do
        enrollments_to_delete.uniq.each(&:destroy!)
      end
    end
  end
end
