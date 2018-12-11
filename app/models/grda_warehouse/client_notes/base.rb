module GrdaWarehouse::ClientNotes
  class Base < GrdaWarehouseBase
    self.table_name = :client_notes
    acts_as_paranoid
    validates_presence_of :note, :type

    attr_accessor :send_notification

    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
    belongs_to :user
    
    scope :window_notes, -> do
      where(type: GrdaWarehouse::ClientNotes::WindowNote)
    end
    
    scope :chronic_justifications, -> do
      where(type: GrdaWarehouse::ClientNotes::ChronicJustification)
    end

    scope :cohort_notes, -> do
      where(type: GrdaWarehouse::ClientNotes::CohortNote)
    end

    def self.type_name
      raise "Must be implemented in sub-class"
    end
    
    def type_name
      self.class.type_name
    end
    
    def self.available_types
      [
        GrdaWarehouse::ClientNotes::WindowNote,
        GrdaWarehouse::ClientNotes::ChronicJustification,
        GrdaWarehouse::ClientNotes::CohortNote,
      ]
    end
    
    def user_can_destroy?(user)
       user.id == self.user_id
    end
  end
end  
  
