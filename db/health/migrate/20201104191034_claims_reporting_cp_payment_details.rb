class ClaimsReportingCpPaymentDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :claims_reporting_cp_payment_details do |t|
      t.references :cp_payment_upload,
                   foreign_key: { to_table: :claims_reporting_cp_payment_uploads },
                   null: false, index: false
      # default index name is too long
      t.index :cp_payment_upload_id, name: 'idx_cpd_on_cp_payment_upload_id'
      t.string  'medicaid_id', null: false
      t.date    'cp_enrollment_start_date', null: false
      t.date    'paid_dos', null: false, index: true
      t.date    'payment_date', null: false, index: true
      t.decimal 'amount_paid', precision: 10, scale: 2
      t.decimal  'adjustment_amount', precision: 10, scale: 2
      t.string  'member_cp_assignment_plan'
      t.string  'cp_name_dsrip'
      t.string  'cp_name_official'
      t.string  'cp_pid'
      t.string  'cp_sl'
      t.string  'month_payment_issued'
      t.string  'paid_num_icn'
      t.timestamps null: false
    end
  end
end
