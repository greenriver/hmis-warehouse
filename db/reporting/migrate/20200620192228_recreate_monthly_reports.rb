class RecreateMonthlyReports < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def up
    if Reporting::MonthlyReports::Base.connection.table_exists? Reporting::MonthlyReports::Base.parent_table
      drop_table Reporting::MonthlyReports::Base.parent_table, force: :cascade
    end
    Reporting::MonthlyReports::Base.ensure_db_structure
  end

  def down
    drop_table Reporting::MonthlyReports::Base.parent_table, force: :cascade
  end
end
