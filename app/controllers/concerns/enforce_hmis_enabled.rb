###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module EnforceHmisEnabled
  extend ActiveSupport::Concern
  included do
    before_action :require_hmis_enabled!

    def hmis_enabled?
      ENV['ENABLE_HMIS_API'] == 'true' && RailsDrivers.loaded.include?(:hmis)
    end

    def hmis_admin_visible?
      HmisEnforcement.hmis_admin_visible?(current_user)
    end

    def require_hmis_enabled!
      return not_authorized! unless HmisEnforcement.hmis_enabled?
    end

    def require_hmis_admin_access!
      return not_authorized! unless HmisEnforcement.hmis_admin_visible?(current_user)
    end
  end
end
