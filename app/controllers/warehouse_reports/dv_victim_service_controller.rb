###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class DvVictimServiceController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_limited, only: [:index]

    def index

    end
  end
end