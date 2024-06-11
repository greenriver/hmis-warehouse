###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientDependentControllers
  extend ActiveSupport::Concern

  included do
    # TODO: START_ACL remove when ACL transition complete
    before_action :set_legacy_implicitly_assume_authorized_access
    # END ACL

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def destination_searchable_client_scope
      client_source.destination_from_searchable_to(current_user)
    end
  end
end
