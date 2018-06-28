module GrdaWarehouse::Import::HMISFiveOne
  class Affiliation < GrdaWarehouse::Hud::Affiliation
    include ::Import::HMISFiveOne::Shared
    include TsqlImport

    setup_hud_column_access( self.hud_csv_headers(version: '5.1') )

    self.hud_key = :AffiliationID

    def self.file_name
      'Affiliation.csv'
    end

  end
end