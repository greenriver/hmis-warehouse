###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ClaimsReporting
  class ClaimsController < ApplicationController
    before_action :require_can_administer_health!

    def index
      raise 'TODO'
    end
  end
end
