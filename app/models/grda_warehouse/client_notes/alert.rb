###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
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
    scope :visible_by, -> (user, client) do
      joins(:client).merge(GrdaWarehouse::Hud::Client.viewable_by(user))
    end

    def notify_users
      # notify related users if the client has a full release (otherwise they can't see the notes)
      if client.present? && client.release_valid?
        NotifyUser.note_added( id ).deliver_later
      end
    end
  end
end
