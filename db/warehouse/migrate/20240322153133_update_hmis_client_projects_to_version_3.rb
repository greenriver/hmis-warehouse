#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class UpdateHmisClientProjectsToVersion3 < ActiveRecord::Migration[6.1]
  def up
    update_view :hmis_client_projects, version: 3
  end

  # the scenic gem seems to have trouble rolling back without this
  def down
    update_view :hmis_client_projects, version: 2
  end
end
