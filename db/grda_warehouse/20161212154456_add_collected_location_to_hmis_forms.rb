class AddCollectedLocationToHmisForms < ActiveRecord::Migration
  def change
    add_column :hmis_forms, :collection_location, :string
  end
end
