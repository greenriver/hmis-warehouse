class AddUsefulClientFieldsToSpmClients < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_spm_clients, :veteran, :boolean, default: false, null: false
    (1..7).to_a.each do |i|
      add_column :hud_report_spm_clients, "m#{i}_head_of_household", :boolean, null: false, default: false
      add_column :hud_report_spm_clients, "m#{i}_reporting_age", :integer
    end
  end
end
