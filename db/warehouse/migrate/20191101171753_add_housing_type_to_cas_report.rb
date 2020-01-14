class AddHousingTypeToCasReport < ActiveRecord::Migration[4.2]
  def change
    add_column :cas_reports, :housing_type, :string
  end
end
