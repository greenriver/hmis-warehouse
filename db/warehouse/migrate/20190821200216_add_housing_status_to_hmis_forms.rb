class AddHousingStatusToHmisForms < ActiveRecord::Migration[4.2]
  def change
    add_column :hmis_forms, :housing_status, :string
  end
end
