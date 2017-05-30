module GrdaWarehouse::ClientNotes
  class Base < GrdaWarehouseBase
    self.table_name = :client_notes
    validates_presence_of :note, :type
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
    
    scope :window_notes, -> do
      where(type: GrdaWarehouse::WindowNote)
    end
    
    scope :chronic_justifications, -> do
      where(type: GrdaWarehouse::ChronicJustification)
    end 
    
    def type
      "Note"
    end
    
    def self.available_types
      [
        GrdaWarehouse::ClientNotes::WindowNote,
        GrdaWarehouse::ClientNotes::ChronicJustification,
      ]
    end
  end
end  
  
