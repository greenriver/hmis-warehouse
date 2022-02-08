###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::ClientNotes
  class WindowNote < Base
    def self.type_name
      'Window Note'
    end

    after_create :notify_users

    def notify_users
      # notify related users if the client has a full release (otherwise they can't see the notes)
      NotifyUser.note_added(id).deliver_later if client.present? && client.release_valid?
    end

    def destroyable_by(user)
      return true if user_id == user.id

      user.can_edit_client_notes? || user.can_edit_window_client_notes?
    end
  end
end
