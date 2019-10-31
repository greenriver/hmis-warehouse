class AddEnrollmentIdToMonthlyReport < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_monthly_reports, :enrollment_id, :integer, null: false
  end
end
