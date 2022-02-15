###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::ClientNotes
  class ServiceNote < Base
    def self.type_name
      'Service Note'
    end

    # anyone who can see the client and project
    scope :visible_by, ->(user, client) do
      joins(:client).merge(GrdaWarehouse::Hud::Client.destination_visible_to(user, source_client_ids: client.source_client_ids)).
        joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(user))
    end

    def destroyable_by(user)
      return true if user_id == user.id

      user.can_edit_client_notes? || user.can_edit_window_client_notes?
    end
  end
end
