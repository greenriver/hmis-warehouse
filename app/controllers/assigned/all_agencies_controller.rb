###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# Shows up as "All Assigned Clients"
module Assigned
  class AllAgenciesController < ApplicationController

    before_action :require_can_manage_all_agencies!

    def index
      @selection = params.dig(:filter, :agency_ids)&.reject(&:empty?)&.map(&:to_i) || []
      users = User.
        active.
        where(id:  GrdaWarehouse::UserClient.active.distinct.pluck(:user_id)).
        order(:first_name, :last_name)
      users = users.where(agency_id: @selection) if @selection.present?
      @users = users.sort_by { |user| user.agency.name }
    end

  end
end