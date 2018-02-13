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

    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :inventories

  end
end