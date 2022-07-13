###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::ClientNotes
  class Alert < Base
    after_create :notify_users

    def self.type_name
      'Client Alert'
    end

    # anyone who can see this client
    scope :visible_by, ->(user, client) do
      joins(:client).merge(GrdaWarehouse::Hud::Client.destination_visible_to(user, source_client_ids: client.source_client_ids))
    end

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
