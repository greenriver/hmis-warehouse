###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
      return false unless hmis_enabled?

      # If the HMIS is enabled, figure out if this user can administer it
      hmis_ds = GrdaWarehouse::DataSource.hmis.pluck(:id).first
      hmis_user = Hmis::User.find_by(id: current_user.id)
      hmis_user.hmis_data_source_id = hmis_ds
      hmis_user&.can_administer_hmis?
    end

    def require_hmis_enabled!
      return not_authorized! unless hmis_enabled?
    end

    def require_hmis_admin_access!
      return not_authorized! unless hmis_admin_visible?
    end
  end
end
