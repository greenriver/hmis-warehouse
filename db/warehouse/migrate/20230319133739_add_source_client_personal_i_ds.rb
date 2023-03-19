class AddSourceClientPersonalIDs < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_spm_clients, :source_client_personal_ids, :string
    add_column :hud_report_apr_clients, :personal_id, :string
    add_column :hud_report_dq_clients, :personal_id, :string
    add_column :hud_report_path_clients, :personal_id, :string
    add_column :hud_report_pit_clients, :personal_id, :string
  end
end
