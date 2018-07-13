module GrdaWarehouse::Import::HMISFiveOne
  class Organization < GrdaWarehouse::Hud::Organization
    include ::Import::HMISFiveOne::Shared
    include TsqlImport

    setup_hud_column_access( GrdaWarehouse::Hud::Organization.hud_csv_headers(version: '5.1') )

    self.hud_key = :OrganizationID

    def self.file_name
      'Organization.csv'
    end

  end
end