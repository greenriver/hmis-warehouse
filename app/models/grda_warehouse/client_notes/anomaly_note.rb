module GrdaWarehouse::ClientNotes
  class AnomalyNote < Base 
    def self.type_name
      "Anomaly Note"
    end

    scope :visible_by, -> (user) do
      if user.can_track_anomalies?
        current_scope
      else
        none
      end
    end
  end
end 
