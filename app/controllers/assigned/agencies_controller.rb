###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Shows up as "My Agency's Clients"
module Assigned
  class AgenciesController < ApplicationController
    before_action :require_can_manage_an_agency!

    # TODO: START_ACL remove when ACL transition complete
    before_action :set_legacy_implicitly_assume_authorized_access
    # # END ACL

    def index
      if current_user.agency
        @users = User.
          active.
          where(agency_id: current_user.agency.id).
          where(id: GrdaWarehouse::UserClient.active.distinct.pluck(:user_id)).
          order(:first_name, :last_name)
      else
        @users = User.where(id: current_user.id)
      end
    end
  end
end
