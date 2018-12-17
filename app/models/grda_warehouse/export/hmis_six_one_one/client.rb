module GrdaWarehouse::Export::HMISSixOneOne
  class Client < GrdaWarehouse::Import::HMISSixOneOne::Client
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::Client.hud_csv_headers(version: '6.11') )

    self.hud_key = :PersonalID

    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    has_many :enrollments_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Enrollment.name, primary_key: [:PersonalID, :data_source_id], foreign_key: [:PersonalID, :data_source_id]


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
        export: export
      )
    end

    # There are situations where clients have multiple source clients,
    # we need to present only one record in the Client.csv file
    def post_process_export_file export_path
      dirty_clients = CSV.read(export_path, headers: true)
      clean_clients = []
      dirty_clients.group_by{|row| row['PersonalID']}.each do |_, source_clients|
        # If there's only one of this client, we'll use it
        if source_clients.count == 1
          clean_clients << source_clients.first
        else
          # sort with newest on-top
          # loop through, replacing only if the particular value is better
          source_clients.sort_by!{|row| row['DateUpdated']}.reverse!
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
      CSV.open(export_path, 'wb', {force_quotes: true}) do |csv|
        return unless clean_clients.any?
        csv << clean_clients.first.headers
        clean_clients.each{|row| csv << row}
      end
    end
  end
end
