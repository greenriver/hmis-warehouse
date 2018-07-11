class CreateMemberStatusReport < ActiveRecord::Migration
  def change
    create_table :member_status_reports do |t|
      t.references :user
      t.references :job
      t.datetime :started_at
      t.datetime :completed_at
      t.string :sender, limit: 100
      t.integer :sent_row_num
      t.integer :sent_column_num
      t.datetime :sent_export_time_stamp
      t.string :receiver
      t.date :report_start_date
      t.date :report_end_date
      t.timestamps null: false
      t.datetime :deleted_at, index: true
    end
    create_table :member_status_report_patients do |t|
      t.references :member_status_report
      t.string :medicaid_id, limit: 12
      t.string :member_first_name, limit: 100
      t.string :member_last_name, limit: 100
      t.string :member_middle_initial, limit: 1
      t.string :member_suffix, limit: 20
      t.date :member_date_of_birth
      t.string :member_sex, limit: 1
      t.string :aco_mco_name, limit: 100
      t.string :aco_mco_pid, limit: 9
      t.string :aco_mco_ls, limit: 10
      t.string :cp_name_official, limit: 100
      t.string :cp_pid, limit: 9
      t.string :cp_sl, limit: 10
      t.string :cp_outreach_status, limit: 30
      t.date :cp_last_contact_date
      t.string :cp_last_contact_face, limit: 1
      t.date :cp_participation_form_date
      t.date :cp_care_plan_sent_pcp_date
      t.date :cp_care_plan_returned_pcp_date
      t.string :key_contact_name_first, limit: 100
      t.string :key_contact_name_last, limit: 100
      t.string :key_contact_phone, limit: 10
      t.string :key_contact_email, limit: 60
      t.string :care_coordinator_first_name, limit: 100
      t.string :care_coordinator_last_name, limit: 100
      t.string :care_coordinator_phone, limit: 10
      t.string :care_coordinator_email, limit: 60
      t.string :record_status, limit: 1
      t.date :record_update_date
      t.date :export_date
      t.timestamps null: false
      t.datetime :deleted_at, index: true
    end
  end
end
