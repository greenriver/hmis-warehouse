class ClaimsReportingCpPaymentUpload < ActiveRecord::Migration[5.2]
  def change
    create_table :claims_reporting_cp_payment_uploads do |t|
      t.references :user
      t.string :original_filename
      t.binary :content
      t.timestamps null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :deleted_at, index: true
    end
  end
end
