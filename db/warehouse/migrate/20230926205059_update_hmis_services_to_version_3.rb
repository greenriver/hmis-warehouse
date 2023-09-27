class UpdateHmisServicesToVersion3 < ActiveRecord::Migration[6.1]
  def up
    # replace union with union all for performance
    update_view :hmis_services, version: 2, revert_to_version: 2
  end

  # teh scenic gem seems to have trouble rolling back without this
  def down
    update_view :hmis_services, version: 2, revert_to_version: 3
  end
end
