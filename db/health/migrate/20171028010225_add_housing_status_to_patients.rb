class AddHousingStatusToPatients < ActiveRecord::Migration[4.2]
  def change
    add_column :patients, :housing_status, :string
    add_column :patients, :housing_status_timestamp, :datetime
  end
end
