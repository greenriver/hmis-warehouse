module GrdaWarehouse::Import::HMISSixOneOne
  class Client < GrdaWarehouse::Hud::Client
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    self.hud_key = :PersonalID
    setup_hud_column_access( GrdaWarehouse::Hud::Client.hud_csv_headers(version: '6.11') )

    def self.file_name
      'Client.csv'
    end
  end
end