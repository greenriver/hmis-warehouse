module GrdaWarehouse::Import::HMISSixOneOne
  class Funder < GrdaWarehouse::Hud::Funder
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    self.hud_key = :FunderID
    setup_hud_column_access( GrdaWarehouse::Hud::Funder.hud_csv_headers(version: '6.11') )

    def self.file_name
      'Funder.csv'
    end

  end
end