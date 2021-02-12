###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting
  class ImportsController < ApplicationController
    before_action :require_can_administer_health!

    def index
      cols = ClaimsReporting::Import.column_names - ['content']
      @imports = ClaimsReporting::Import.order(created_at: :desc).select(cols)
    end
  end
end
