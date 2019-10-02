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
      @users = User.
        active.
        order(:first_name, :last_name).
        sort_by { |user| user.agency.name }
    end

  end
end