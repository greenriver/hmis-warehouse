class AddHealthPrioritizedToClients < ActiveRecord::Migration[5.2]
  def change
    add_column :Client, :health_prioritized, :string
    add_column :hmis_forms, :vispdat_physical_disability_answer, :string
    add_column :hmis_forms, :vispdat_physical_disability_updated_at, :datetime
  end
end
