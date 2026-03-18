###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisEnforcement
  def self.hmis_enabled?
    ENV['ENABLE_HMIS_API'] == 'true' && RailsDrivers.loaded.include?(:hmis)
  end

  def self.hmis_admin_visible?(user)
    return false unless hmis_enabled?
    return false unless GrdaWarehouse::DataSource.hmis.exists?

    # If the HMIS is enabled, figure out if this user can administer.
    # Return true if the user can administer any HMIS data source.
    hmis_user = Hmis::User.find_by(id: user.id)
    hmis_user&.can_administer_hmis?
  end
end
