class AddHousingTypeToCasReport < ActiveRecord::Migration
  def change
    add_column :cas_reports, :housing_type, :string
  end
end
