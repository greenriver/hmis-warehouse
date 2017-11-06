class AddHousingStatusToPatients < ActiveRecord::Migration
  def change
    add_column :patients, :housing_status, :string
    add_column :patients, :housing_status_timestamp, :datetime
  end
end
