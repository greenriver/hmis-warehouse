###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientDependentControllers
  extend ActiveSupport::Concern

  included do
    def client_source
      GrdaWarehouse::Hud::Client
    end

    def destination_searchable_client_scope
      client_source.destination_from_searchable_to(current_user)
    end
  end
end
