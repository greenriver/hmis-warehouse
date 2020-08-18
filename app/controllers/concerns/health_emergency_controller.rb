###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthEmergencyController
  extend ActiveSupport::Concern
  include ClientPathGenerator

  included do
    before_action :require_health_emergency!
    before_action :set_client

    def require_health_emergency!
      return true if health_emergency?

      not_authorized!
    end

    private def set_client
      @client = searchable_client_scope(id: params[:client_id].to_i).find(params[:client_id].to_i)
    end
  end
end
