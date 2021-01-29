###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class DashboardsController < ApplicationController
  before_action :require_can_view_censuses!
  def index
  end
end
