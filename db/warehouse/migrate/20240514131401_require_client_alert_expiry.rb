#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class RequireClientAlertExpiry < ActiveRecord::Migration[7.0]
  def up
    unexpired = Hmis::ClientAlert.with_deleted.where(expiration_date: nil)
    unexpired.update_all("expiration_date=created_at + interval '1 month'")

    safety_assured { change_column_null :hmis_client_alerts, :expiration_date, false }
  end

  def down
    safety_assured { change_column_null :hmis_client_alerts, :expiration_date, true }
  end
end
