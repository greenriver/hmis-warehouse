module GrdaWarehouse::Import::HMISSixOneOne
  class Funder < GrdaWarehouse::Hud::Funder
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport

    setup_hud_column_access( self.hud_csv_headers(version: '6.11') )

    def self.file_name
      'Funder.csv'
    end

  end
end