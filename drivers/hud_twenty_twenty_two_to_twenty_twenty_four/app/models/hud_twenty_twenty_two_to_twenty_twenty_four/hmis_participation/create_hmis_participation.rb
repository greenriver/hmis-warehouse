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
          key = "#{row['OrganizationID']}_ds_#{row['data_source_id']}"
          h[key] = row['VictimServiceProvider']
        end
      end
    end

    private def parse_projects
      @parse_projects ||= [].tap do |arr|
        reference(:project) do |row|
          participation_id = "GR-#{row['ProjectID']}"[0..31]

          key = "#{row['OrganizationID']}_ds_#{row['data_source_id']}"
          participation_type = if victim_service_providers[key] == 1
            2
          else
            row['HMISParticipatingProject']
          end

          timestamp = Time.current
          timestamp = timestamp.strftime('%Y-%m-%d %H:%M:%S') unless row['data_source_id'].present?

          entry = {
            HMISParticipationID: participation_id,
            ProjectID: row['ProjectID'],
            HMISParticipationType: participation_type,
            HMISParticipationStatusStartDate: row['OperatingStartDate'],
            HMISParticipationStatusEndDate: row['OperatingEndDate'],
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
