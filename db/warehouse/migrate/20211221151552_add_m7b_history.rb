class AddM7bHistory < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_spm_clients, :m7b_history, :jsonb
    add_column :hud_report_spm_clients, :m2_project_id, :integer
    add_column :hud_report_spm_clients, :m3_project_id, :integer
    add_column :hud_report_spm_clients, :m4_project_id, :integer
    add_column :hud_report_spm_clients, :m5_project_id, :integer
    add_column :hud_report_spm_clients, :m7a1_project_id, :integer
    add_column :hud_report_spm_clients, :m7b_project_id, :integer
  end
end
