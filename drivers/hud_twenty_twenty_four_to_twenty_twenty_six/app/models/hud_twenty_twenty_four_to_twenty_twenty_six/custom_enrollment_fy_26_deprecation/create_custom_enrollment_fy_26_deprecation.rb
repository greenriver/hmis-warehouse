###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix
  module CustomEnrollmentFy26Deprecation
    class CreateCustomEnrollmentFy26Deprecation
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
            # Extract sexual orientation and translation assistance needed fields from the 2024 Enrollment.csv row
            custom_enrollment_fy_26_deprecation_fields = extract_custom_enrollment_fy_26_deprecation_fields(row)

            # Only create a CustomEnrollmentFY26Deprecation row if there are sexual orientation or translation assistance needed values
            next if custom_enrollment_fy_26_deprecation_fields.values.all?(&:blank?)

            # Create the CustomEnrollmentFY26Deprecation row with the extracted fields
            entry = {
              EnrollmentID: row['EnrollmentID'],
              PersonalID: row['PersonalID'],
              SexualOrientation: custom_enrollment_fy_26_deprecation_fields['SexualOrientation'],
              SexualOrientationOther: custom_enrollment_fy_26_deprecation_fields['SexualOrientationOther'],
              TranslationNeeded: custom_enrollment_fy_26_deprecation_fields['TranslationNeeded'],
              PreferredLanguage: custom_enrollment_fy_26_deprecation_fields['PreferredLanguage'],
              PreferredLanguageDifferent: custom_enrollment_fy_26_deprecation_fields['PreferredLanguageDifferent'],
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

      private def extract_custom_enrollment_fy_26_deprecation_fields(row)
        {
          'SexualOrientation' => row['SexualOrientation'],
          'SexualOrientationOther' => row['SexualOrientationOther'],
          'TranslationNeeded' => row['TranslationNeeded'],
          'PreferredLanguage' => row['PreferredLanguage'],
          'PreferredLanguageDifferent' => row['PreferredLanguageDifferent'],
        }
      end
    end
  end
end
