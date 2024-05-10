#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddIndexServicesHudTypes < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_index :Services, [:RecordType, :TypeProvided], name: 'idx_services_hud_types'
    end
  end
end
