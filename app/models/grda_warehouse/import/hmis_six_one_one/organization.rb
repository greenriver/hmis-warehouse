module GrdaWarehouse::Import::HMISSixOneOne
  class Organization < GrdaWarehouse::Hud::Organization
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    self.hud_key = :OrganizationID
    setup_hud_column_access( GrdaWarehouse::Hud::Organization.hud_csv_headers(version: '6.11') )

    def self.file_name
      'Organization.csv'
    end

  end
end