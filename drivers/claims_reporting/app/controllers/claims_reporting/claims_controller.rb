###
# Copyright Green River Data Group, Inc.
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
