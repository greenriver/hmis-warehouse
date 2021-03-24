###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientDependentControllers
  extend ActiveSupport::Concern

  included do
    def client_source
      GrdaWarehouse::Hud::Client
    end

    def searchable_client_scope(id: nil)
      destination_client = client_source.find_by(id: id) if id
      scope = client_source.destination_visible_to(current_user)
      scope = scope.where(id: destination_client.source_clients.pluck(:id)) if destination_client
      scope
    end
  end
end
