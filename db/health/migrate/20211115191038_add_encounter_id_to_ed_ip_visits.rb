class AddEncounterIdToEdIpVisits < ActiveRecord::Migration[5.2]
  def change
    add_column :ed_ip_visits, :encounter_id, :string
    add_index :ed_ip_visits, :encounter_id, unique: true

    add_column :loaded_ed_ip_visits, :encounter_id, :string
  end
end
