###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::HmisParticipation
  class CreateHmisParticipation
    include ::HudTwentyTwentyTwoToTwentyTwentyFour::References

    def process(_row)
      parse_projects.each do |row|
        yield(row)
      end

      nil
    end

    private def victim_service_providers
      @victim_service_providers ||= {}.tap do |h|
        reference(:organization) do |row|
          h[row['OrganizationID']] = row['VictimServiceProvider']
        end
      end
    end

    private def parse_projects
      @parse_projects ||= [].tap do |arr|
        reference(:project) do |row|
          participation_id = "GR-#{row['ProjectID']}"[0..31]
          participation_type = if victim_service_providers[row['OrganizationID']] == 1
            2
          else
            row['HMISParticipatingProject']
          end
          arr << {
            HMISParticipationID: participation_id,
            ProjectID: row['ProjectID'],
            HMISParticipationType: participation_type,
            HMISParticipationStatusStartDate: row['OperatingStartDate'],
            HMISParticipationStatusEndDate: row['OperatingEndDate'],
            DateCreated: Time.current,
            DateUpdated: Time.current,
            UserID: row['UserID'],
            DateDeleted: nil,
            ExportID: row['ExportID'],
          }.with_indifferent_access
        end
      end
    end
  end
end
