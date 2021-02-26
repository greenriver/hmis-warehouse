class CreateHudReportSpmClients < ActiveRecord::Migration[5.2]
  def change
    create_table :hud_report_spm_clients do |t|
      t.integer :client_id, null: false
      t.integer :data_source_id, null: false
      t.integer :report_instance_id, null: false

      t.index [:client_id, :data_source_id, :report_instance_id], unique: true, name: 'spm_client_conflict_columns'
      t.timestamps
      t.timestamp :deleted_at

      # required for HudReports::ReportCell.new_member and  HudReports::ReportCell.copy_member
      t.date :dob
      t.string :first_name
      t.string :last_name

      t.integer :m1a_es_sh_days
      t.integer :m1a_es_sh_th_days
      t.integer :m1b_es_sh_ph_days
      t.integer :m1b_es_sh_th_ph_days
      t.jsonb :m1_history

      t.integer :m2_exit_from_project_type
      t.integer :m2_exit_to_destination
      t.integer :m2_reentry_days
      t.jsonb :m2_history

      t.integer :m3_active_project_types, array: true
    end
  end
end
