class AddHousingStatusToHmisForms < ActiveRecord::Migration
  def change
    add_column :hmis_forms, :housing_status, :string
  end
end
