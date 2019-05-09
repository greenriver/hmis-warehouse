class AddEnrollmentIdToMonthlyReport < ActiveRecord::Migration
  def change
    add_column :warehouse_monthly_reports, :enrollment_id, :integer, null: false
  end
end
