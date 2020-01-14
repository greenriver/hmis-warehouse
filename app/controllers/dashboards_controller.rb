###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class DashboardsController < ApplicationController
  before_action :require_can_view_censuses!
  def index
  end
end
