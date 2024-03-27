#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class UpdateHmisHouseholdsToVersion6 < ActiveRecord::Migration[6.1]
  def up
    update_view :hmis_households, version: 6
  end

  # the scenic gem seems to have trouble rolling back without this
  def down
    update_view :hmis_households, version: 5
  end
end
