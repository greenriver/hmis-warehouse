###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::ClientNotes
  class EmergencyContact < Base
    def self.type_name
      'Emergency Contact'
    end

    def destroyable_by(user)
      return true if user_id == user.id

      user.can_edit_client_notes? || user.can_edit_window_client_notes?
    end
  end
end
