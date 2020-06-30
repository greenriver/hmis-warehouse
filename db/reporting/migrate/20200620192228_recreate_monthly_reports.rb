class RecreateMonthlyReports < ActiveRecord::Migration[5.2]
  def up
    Reporting::MonthlyReports::Base.ensure_db_structure
  end

  def down
    drop_table Reporting::MonthlyReports::Base.parent_table, force: :cascade
  end
end
