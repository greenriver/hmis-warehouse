module GrdaWarehouse::Import::HMISFiveOne
  class Inventory < GrdaWarehouse::Hud::Inventory
    include ::Import::HMISFiveOne::Shared
    include TsqlImport

    setup_hud_column_access( self.hud_csv_headers(version: '5.1') )

    self.hud_key = :InventoryID

    def self.file_name
      'Inventory.csv'
    end
  end
end