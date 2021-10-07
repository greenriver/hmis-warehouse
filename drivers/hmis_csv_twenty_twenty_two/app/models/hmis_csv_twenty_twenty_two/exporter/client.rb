###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Client < GrdaWarehouse::Hud::Client
    include ::HmisCsvTwentyTwentyTwo::Exporter::Shared
    self.hud_key = :PersonalID
    setup_hud_column_access(GrdaWarehouse::Hud::Client.hud_csv_headers(version: '2022'))

    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    has_many :enrollments_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:PersonalID, :data_source_id], foreign_key: [:PersonalID, :data_source_id]

    def export! client_scope:, path:, export:
      case export.period_type
      when 3
        export_scope = client_scope
      when 1
        export_scope = client_scope.
          modified_within_range(range: (export.start_date..export.end_date))
      end

      export_to_path(
        export_scope: export_scope,
        path: path,
        export: export,
      )
    end

    def apply_overrides(row, data_source_id:) # rubocop:disable Lint/UnusedMethodArgument
      row[:FirstName] = row[:FirstName][0...50] if row[:FirstName]
      row[:MiddleName] = row[:MiddleName][0...50] if row[:MiddleName]
      row[:LastName] = row[:LastName][0...50] if row[:LastName]
      row[:NameSuffix] = row[:NameSuffix][0...50] if row[:NameSuffix]

      [
        :NameDataQuality,
        :SSNDataQuality,
        :DOBDataQuality,
        :GenderNone,
        :Female,
        :Male,
        :NoSingleGender,
        :Transgender,
        :Questioning,
        :VeteranStatus,
        :AmIndAKNative,
        :Asian,
        :BlackAfAmerican,
        :NativeHIPacific,
        :White,
        :Ethnicity,
        :VeteranStatus,
      ].each do |required_column|
        row[required_column] = 99 if row[required_column].blank?
      end

      row
    end

    # There are situations where clients have multiple source clients,
    # we need to present only one record in the Client.csv file
    def post_process_export_file export_path
      dirty_clients = CSV.read(export_path, headers: true)
      clean_clients = []
      dirty_clients.group_by { |row| row['PersonalID'] }.each do |_, source_clients|
        # If there's only one of this client, we'll use it
        if source_clients.count == 1
          clean_clients << source_clients.first
        else
          # sort with newest on-top
          # loop through, replacing only if the particular value is better
          source_clients.sort_by! { |row| row['DateUpdated'] }.reverse!
          clean_client = source_clients.first
          source_clients.drop(1).each do |row|
            # Name
            if clean_client['NameDataQuality'] != '1' && row['NameDataQuality'] == '1'
              clean_client['NameDataQuality'] = row['NameDataQuality']
              clean_client['FirstName'] = row['FirstName']
              clean_client['MiddleName'] = row['MiddleName']
              clean_client['LastName'] = row['LastName']
              clean_client['NameSuffix'] = row['NameSuffix']
            end
            # SSN
            if clean_client['SSNDataQuality'] != '1' && row['SSNDataQuality'] == '1'
              clean_client['SSNDataQuality'] = row['SSNDataQuality']
              clean_client['SSN'] = row['SSN']
            end
            # DOB
            if clean_client['DOBDataQuality'] != '1' && row['DOBDataQuality'] == '1'
              clean_client['DOBDataQuality'] = row['DOBDataQuality']
              clean_client['DOB'] = row['DOB']
            end
          end
          clean_clients << clean_client
        end
      end

      CSV.open(export_path, 'wb', { force_quotes: true }) do |csv|
        break unless clean_clients.any?

        csv << clean_clients.first.headers
        clean_clients.each { |row| csv << row }
      end
    end
  end
end
