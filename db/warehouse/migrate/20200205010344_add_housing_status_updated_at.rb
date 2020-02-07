class AddHousingStatusUpdatedAt < ActiveRecord::Migration[5.2]
  def change
    add_column :hmis_forms, :housing_status_updated_at, :datetime
  end
end
