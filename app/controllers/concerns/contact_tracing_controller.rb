###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ContactTracingController
  extend ActiveSupport::Concern

  included do
    before_action :require_health_emergency_contact_tracing!
    before_action :require_can_edit_health_emergency_contact_tracing!

    def require_health_emergency_contact_tracing!
      return true if health_emergency_contact_tracing?

      not_authorized!
    end

    def health_emergency_contact_tracing?
      health_emergency_contact_tracing.present?
    end

    def health_emergency_contact_tracing
      @health_emergency_contact_tracing ||= GrdaWarehouse::Config.get(:health_emergency_tracing)
    end
    helper_method :health_emergency_contact_tracing
  end
end
