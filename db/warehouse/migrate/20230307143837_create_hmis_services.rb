class CreateHmisServices < ActiveRecord::Migration[6.1]
  def change
    create_view :hmis_services
  end
end
