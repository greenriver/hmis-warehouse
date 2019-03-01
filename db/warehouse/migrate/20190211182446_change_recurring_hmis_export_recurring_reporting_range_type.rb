class ChangeRecurringHmisExportRecurringReportingRangeType < ActiveRecord::Migration
  def up
    change_column :recurring_hmis_exports, :reporting_range, :string, using: "CASE reporting_range WHEN 1 THEN 'fixed'
      WHEN 2 THEN 'n_days' WHEN 3 THEN 'month' WHEN 4 THEN 'year' END"
  end

  def down
    change_column :recurring_hmis_exports, :reporting_range, :integer, using: "CASE reporting_range WHEN 'fixed' THEN 1
      WHEN 'n_days' THEN 2 WHEN 'month' THEN 3 WHEN 'year' THEN 4 END"
  end
end
