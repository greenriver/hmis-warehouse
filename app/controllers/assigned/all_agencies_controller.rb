###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Shows up as "All Assigned Clients"
module Assigned
  class AllAgenciesController < ApplicationController
    before_action :require_can_manage_all_agencies!

    def index
      @selection = params.dig(:filter, :agency_id)&.to_i || Agency.first.id
      users = User.
        active.
        where(id: GrdaWarehouse::UserClient.active.distinct.pluck(:user_id)).
        order(:first_name, :last_name)
      users = users.where(agency_id: @selection) if @selection.present?
      @users = users.sort_by { |user| user.agency.name }
    end
  end
end
