module GrdaWarehouse::Import::HMISFiveOne
  class Client < GrdaWarehouse::Hud::Client
    include ::Import::HMISFiveOne::Shared
    include TsqlImport

    setup_hud_column_access( GrdaWarehouse::Hud::Client.hud_csv_headers(version: '5.1') )

    self.hud_key = :PersonalID

    def self.file_name
      'Client.csv'
    end
  end
end