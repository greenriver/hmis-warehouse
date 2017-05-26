module GrdaWarehouse::ClientNotes
  class Base < GrdaWarehouseBase
    self.table_name = :client_notes
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
    
    def note_options
      [
        "Chronic Justification",
        "Window Note",
      ]
    end
  end
end  
  
