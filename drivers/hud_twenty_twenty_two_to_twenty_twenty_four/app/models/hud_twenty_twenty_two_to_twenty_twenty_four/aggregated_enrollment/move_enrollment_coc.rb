###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::AggregatedEnrollment
  class MoveEnrollmentCoC
    include ::HudTwentyTwentyTwoToTwentyTwentyFour::References

    def process(row)
      row['EnrollmentCoC'] = entry_enrollment_coc(row)

      row
    end

    private def entry_enrollment_coc(enrollment_row)
      @entry_enrollment_coc ||= {}.tap do |h|
        reference(:enrollment_coc) do |row|
          next unless row['DataCollectionStage'].to_i == 1

          key = row['HouseholdID'].presence || "en_#{row['EnrollmentID']}"
          key += "_ds_#{row['data_source_id']}"
          h[key] ||= row['CoCCode'] if HudUtility2024.valid_coc?(row['CoCCode'])
        end
      end
      key = enrollment_row['HouseholdID'].presence || "en_#{enrollment_row['EnrollmentID']}"
      key += "_ds_#{row['data_source_id']}"
      @entry_enrollment_coc[key]
    end
  end
end
