class HmisServicesViewV5 < ActiveRecord::Migration[6.1]
  def up
    update_view :hmis_services, version: 5
  end
  def down
    update_view :hmis_services, version: 4
  end
end
