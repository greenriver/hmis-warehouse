module GrdaWarehouse::Import::HMISSixOneOne
  class Service < GrdaWarehouse::Hud::Service
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport

    setup_hud_column_access( self.hud_csv_headers(version: '6.11') )

    def self.date_provided_column
      :DateProvided
    end

    def self.file_name
      'Services.csv'
    end

    def self.should_log?
      true
    end

    def self.to_log
      @to_log ||= {
        hud_key: self.hud_key,
        personal_id: :PersonalID,
        effective_date: :DateProvided,
        data_source_id: :data_source_id,
      }
    end
  end
end