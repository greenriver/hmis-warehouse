###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::ClientNotes
  class AnomalyNote < Base
    def self.type_name
      'Anomaly Note'
    end

    # hide previous declaration of :visible_by, we'll use this one
    replace_scope :visible_by, ->(user) do
      if user.can_track_anomalies?
        current_scope
      else
        none
      end
    end

    def destroyable_by(user)
      return true if user_id == user.id

      user.can_edit_client_notes?
    end
  end
end
