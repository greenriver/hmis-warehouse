class UpdateHmisClientProjectsToVersion2 < ActiveRecord::Migration[6.1]
  def up
    # replace union with union all for performance
    update_view :hmis_client_projects, version: 2
  end

  # the scenic gem seems to have trouble rolling back without this
  def down
    update_view :hmis_client_projects, version: 1
  end
end
