###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisEnforcement
  def self.hmis_enabled?
    ENV['ENABLE_HMIS_API'] == 'true' && RailsDrivers.loaded.include?(:hmis)
  end

  def self.hmis_admin_visible?(user)
    return false unless hmis_enabled?

    # If the HMIS is enabled, figure out if this user can administer it
    hmis_ds = GrdaWarehouse::DataSource.hmis.pluck(:id).first
    hmis_user = Hmis::User.find_by(id: user.id)
    hmis_user.hmis_data_source_id = hmis_ds
    hmis_user&.can_administer_hmis?
  end
end
