#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class DropClientProjectsView < ActiveRecord::Migration[6.1]
  def up
    drop_view :hmis_client_projects, revert_to_version: 3
  end

  def down
    create_view :hmis_client_projects, version: 3
  end
end
