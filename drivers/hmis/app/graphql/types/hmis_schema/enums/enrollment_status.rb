###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::EnrollmentStatus < Types::BaseEnum
    description 'Status of this enrollment'
    graphql_name 'EnrollmentStatus'

    value 'OWN_ENTRY_INCOMPLETE', 'Entry Incomplete'
    value 'ANY_ENTRY_INCOMPLETE', 'Household Entry Incomplete'
    value 'ACTIVE', 'Active'
    value 'EXITED', 'Exited'
    value 'OWN_EXIT_INCOMPLETE', 'Exit Incomplete'
    value 'ANY_EXIT_INCOMPLETE', 'Household Exit Incomplete'

    def self.from_enrollment(enrollment)
      return 'OWN_ENTRY_INCOMPLETE' if enrollment.in_progress?

      return 'OWN_EXIT_INCOMPLETE' if enrollment.exit_in_progress?

      # If there are other household members, check for any incomplete entries or exits
      household_members = enrollment.household_members
      if household_members.count > 1
        return 'ANY_ENTRY_INCOMPLETE' if household_members.in_progress.exists?
        return 'ANY_EXIT_INCOMPLETE' if household_members.find(&:exit_in_progress?).present?
      end

      return 'EXITED' if enrollment.exit_date.present?

      'ACTIVE'
    end
  end
end
