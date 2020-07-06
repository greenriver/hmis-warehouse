###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::ClientNotes
  class EmergencyContact < Base
    def self.type_name
      'Emergency Contact'
    end

    # anyone who can see this client
    scope :visible_by, -> (user, client) do
      joins(:client).merge(GrdaWarehouse::Hud::Client.viewable_by(user))
    end
  end
end
