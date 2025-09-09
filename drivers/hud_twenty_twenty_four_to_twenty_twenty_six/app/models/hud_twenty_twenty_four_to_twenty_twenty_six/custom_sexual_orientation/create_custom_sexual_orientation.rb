###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix
  module CustomSexualOrientation
    class CreateCustomSexualOrientation
      include ::HudTwentyTwentyFourToTwentyTwentySix::References

      def process(_row)
        parse_enrollments.each do |row|
          yield(row)
        end

        nil
      end

      private def parse_enrollments
        @parse_enrollments ||= [].tap do |arr|
          reference(:enrollment) do |row|
            # Extract sexual orientation fields from the 2024 Enrollment.csv row
            sexual_orientation_fields = extract_sexual_orientation_fields(row)

            # Only create a CustomSexualOrientation row if there are sexual orientation values
            next if sexual_orientation_fields.values.all?(&:blank?)

            # Create the CustomSexualOrientation row with the extracted fields
            entry = {
              EnrollmentID: row['EnrollmentID'],
              PersonalID: row['PersonalID'],
              SexualOrientation: sexual_orientation_fields['SexualOrientation'],
              SexualOrientationOther: sexual_orientation_fields['SexualOrientationOther'],
              DateCreated: row['DateCreated'],
              DateUpdated: row['DateUpdated'],
              UserID: row['UserID'],
              DateDeleted: row['DateDeleted'],
              ExportID: row['ExportID'],
            }.with_indifferent_access

            arr << entry
          end
        end
      end

      private def extract_sexual_orientation_fields(row)
        {
          'SexualOrientation' => row['SexualOrientation'],
          'SexualOrientationOther' => row['SexualOrientationOther'],
        }
      end
    end
  end
end
