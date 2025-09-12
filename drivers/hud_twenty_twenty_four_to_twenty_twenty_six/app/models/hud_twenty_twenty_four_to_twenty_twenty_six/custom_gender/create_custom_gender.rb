###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix
  module CustomGender
    class CreateCustomGender
      include ::HudTwentyTwentyFourToTwentyTwentySix::References

      def process(_row)
        parse_clients.each do |row|
          yield(row)
        end

        nil
      end

      private def parse_clients
        @parse_clients ||= [].tap do |arr|
          reference(:client) do |row|
            # Extract gender fields from the 2024 Client.csv row
            gender_fields = extract_gender_fields(row)

            # Only create a CustomGender row if there are gender values
            next if gender_fields.values.all?(&:blank?)

            # Create the CustomGender row with the extracted fields
            entry = {
              PersonalID: row['PersonalID'],
              Woman: gender_fields['Woman'],
              Man: gender_fields['Man'],
              NonBinary: gender_fields['NonBinary'],
              CulturallySpecific: gender_fields['CulturallySpecific'],
              Transgender: gender_fields['Transgender'],
              Questioning: gender_fields['Questioning'],
              DifferentIdentity: gender_fields['DifferentIdentity'],
              GenderNone: gender_fields['GenderNone'],
              DifferentIdentityText: gender_fields['DifferentIdentityText'],
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

      private def extract_gender_fields(row)
        {
          'Woman' => row['Woman'],
          'Man' => row['Man'],
          'NonBinary' => row['NonBinary'],
          'CulturallySpecific' => row['CulturallySpecific'],
          'Transgender' => row['Transgender'],
          'Questioning' => row['Questioning'],
          'DifferentIdentity' => row['DifferentIdentity'],
          'GenderNone' => row['GenderNone'],
          'DifferentIdentityText' => row['DifferentIdentityText'],
        }
      end
    end
  end
end
