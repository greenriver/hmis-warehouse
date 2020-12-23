class AddImportedToVaccinations < ActiveRecord::Migration[5.2]
  def change
    add_column :health_emergency_vaccinations, :health_vaccination_id, :integer
  end
end
