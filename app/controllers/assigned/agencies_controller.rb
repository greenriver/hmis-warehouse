###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Assigned
  class AgenciesController < ApplicationController

    before_action :require_can_search_window!

    def index

    end
  end
end