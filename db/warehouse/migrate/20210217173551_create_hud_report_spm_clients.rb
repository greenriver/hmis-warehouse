class CreateHudReportSpmClients < ActiveRecord::Migration[5.2]
  def change
    create_table :hud_report_spm_clients do |t|
      t.integer :client_id
      t.integer :data_source_id
      t.integer :report_instance_id

      t.index [:client_id, :data_source_id, :report_instance_id], unique: true,  name: 'spm_client_conflict_columns'
      t.timestamps
      t.timestamp :deleted_at

      t.date :dob
      t.string :first_name #required for HudReports::ReportCell.new_member and  HudReports::ReportCell.copy_member
      t.string :last_name

      t.integer :m1a_es_sh_days
      t.integer :m1a_es_sh_th_days
      t.integer :m1b_es_sh_ph_days
      t.integer :m1b_es_sh_th_ph_days

      # TODO some audit record of bed_nights present at the time of the report
      # t.date :m1a_es_sh_dates, array: true
      # t.date :m1a_es_sh_th_dates, array: true
      # t.date :m1b_es_sh_ph_dates, array: true
      # t.date :m1b_es_sh_th_ph_dates, array: true
    end
  end
end
