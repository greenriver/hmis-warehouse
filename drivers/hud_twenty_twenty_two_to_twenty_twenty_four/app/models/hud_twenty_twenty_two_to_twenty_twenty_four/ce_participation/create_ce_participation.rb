###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::CeParticipation
  class CreateCeParticipation
    include ::HudTwentyTwentyTwoToTwentyTwentyFour::References

    def process(_row)
      parse_projects.each do |row|
        yield(row)
      end

      nil
    end

    private def parse_projects
      @parse_projects ||= [].tap do |arr|
        reference(:project) do |row|
          participation_id = "GR-#{row['ProjectID']}"[0..31]
          timestamp = row['DateUpdated']

          entry = {
            CEParticipationID: participation_id,
            ProjectID: row['ProjectID'],
            AccessPoint: 0,
            PreventionAssessment: nil,
            CrisisAssessment: nil,
            HousingAssessment: nil,
            DirectServices: nil,
            ReceivesReferrals: 0,
            CEParticipationStatusStartDate: row['OperatingStartDate'],
            CEParticipationStatusEndDate: row['OperatingEndDate'],
            DateCreated: timestamp,
            DateUpdated: timestamp,
            UserID: row['UserID'],
            DateDeleted: nil,
            ExportID: row['ExportID'],
            data_source_id: row['data_source_id'],
          }.with_indifferent_access

          arr << entry
        end
      end
    end
  end
end
