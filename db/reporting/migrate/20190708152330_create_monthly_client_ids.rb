class CreateMonthlyClientIds < ActiveRecord::Migration[4.2]
  def change
    create_table :warehouse_monthly_client_ids do |t|
      t.string :report_type, null: false
      t.integer :client_id, null: false
    end
    add_index :warehouse_monthly_reports, [:client_id]
    add_index :warehouse_monthly_client_ids, [:report_type, :client_id]
  end
end
