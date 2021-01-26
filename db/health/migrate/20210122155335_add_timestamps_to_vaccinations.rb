class AddTimestampsToVaccinations < ActiveRecord::Migration[5.2]
  def change
    add_column :vaccinations, :epic_row_created, :datetime
    add_column :vaccinations, :epic_row_updated, :datetime
  end
end
