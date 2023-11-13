class UpdateHmisServicesToVersion4 < ActiveRecord::Migration[6.1]
  def up
    update_view :hmis_services, version: 4
  end

  # the scenic gem seems to have trouble rolling back without this
  def down
    update_view :hmis_services, version: 3
  end
end
