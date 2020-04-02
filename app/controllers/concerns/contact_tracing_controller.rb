###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ContactTracingController
  extend ActiveSupport::Concern

  included do
    before_action :require_health_emergency!
    before_action :require_can_edit_health_emergency_contact_tracing!

    def require_health_emergency!
      return true if health_emergency?

      not_authorized!
    end
  end
end
