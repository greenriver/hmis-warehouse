###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

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
