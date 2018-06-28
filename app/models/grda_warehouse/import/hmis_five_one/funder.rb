module GrdaWarehouse::Import::HMISFiveOne
  class Funder < GrdaWarehouse::Hud::Funder
    include ::Import::HMISFiveOne::Shared
    include TsqlImport

    setup_hud_column_access( self.hud_csv_headers(version: '5.1') )

    self.hud_key = :FunderID

    def self.file_name
      'Funder.csv'
    end

  end
end