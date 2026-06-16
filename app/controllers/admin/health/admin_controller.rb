###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin::Health
  class AdminController < HealthController
    before_action :require_has_administrative_access_to_health!

    def index
    end
  end
end
