class AddCollectedLocationToHmisForms < ActiveRecord::Migration[4.2]
  def change
    add_column :hmis_forms, :collection_location, :string
  end
end
