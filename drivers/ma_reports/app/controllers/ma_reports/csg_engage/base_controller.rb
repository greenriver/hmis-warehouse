###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class BaseController < ApplicationController
    before_action :require_can_view_imports!

    def index
    end
  end
end
