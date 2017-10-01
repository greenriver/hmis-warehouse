module GrdaWarehouse::Export::HMISSixOneOne
  class Inventory < GrdaWarehouse::Import::HMISSixOneOne::Inventory
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :InventoryID,
        :ProjectID,
        :CoCCode,
        :InformationDate,
        :HouseholdType,
        :Availability,
        :UnitInventory,
        :BedInventory,
        :CHBedInventory,
        :VetBedInventory,
        :YouthBedInventory,
        :BedType,
        :InventoryStartDate,
        :InventoryEndDate,
        :HMISParticipatingBeds,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :InventoryID

    def self.export! project_scope:, path:, export:
      inventory_scope = joins(:project).merge(project_scope)
      export_to_path(export_scope: inventory_scope, path: path, export: export)
    end
  end
end