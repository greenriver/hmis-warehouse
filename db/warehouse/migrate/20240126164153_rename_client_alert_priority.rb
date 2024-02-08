#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class RenameClientAlertPriority < ActiveRecord::Migration[6.1]
  def change
    # Column is not in use yet, so it's safe to rename
    safety_assured { rename_column :hmis_client_alerts, :severity, :priority }
  end
end
