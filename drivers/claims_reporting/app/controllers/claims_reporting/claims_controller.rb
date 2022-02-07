###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting
  class ClaimsController < ApplicationController
    before_action :require_can_administer_health!

    def index
      raise 'TODO'
    end
  end
end
