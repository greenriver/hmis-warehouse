module GrdaWarehouse::Import::HMISFiveOne
  class Service < GrdaWarehouse::Hud::Service
    include ::Import::HMISFiveOne::Shared
    include TsqlImport

    setup_hud_column_access( self.hud_csv_headers(version: '5.1') )

    self.hud_key = :ServicesID
    def self.date_provided_column
      :DateProvided
    end

    def self.file_name
      'Services.csv'
    end
  end
end