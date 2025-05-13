###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::Enrollment
  class MoveEnrollmentCoC
    include ::HudTwentyTwentyFourToTwentyTwentySix::References

    def process(row)
      row['EnrollmentCoC'] = entry_enrollment_coc(row['HouseholdID'])

      row
    end

    private def entry_enrollment_coc(household_id)
      @entry_enrollment_coc ||= {}.tap do |h|
        reference(:enrollment_coc) do |row|
          next unless row['DataCollectionStage'].to_i == 1

          h[row['HouseholdID']] ||= row['CoCCode']
        end
      end
      @entry_enrollment_coc[household_id]
    end
  end
end
