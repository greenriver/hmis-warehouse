class AddTerminalStatusToCasReports < ActiveRecord::Migration
  def change
    add_column :cas_reports, :terminal_status, :string
  end
end
