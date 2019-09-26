###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# Shows up as "My Agency's Clients"
module Assigned
  class AgenciesController < ApplicationController

    before_action :require_can_manage_an_agency!

    def index

    end

    def require_can_manage_an_agency!
      not_authorized! unless can_manage_agency? || can_manage_all_agencies?
    end
  end
end