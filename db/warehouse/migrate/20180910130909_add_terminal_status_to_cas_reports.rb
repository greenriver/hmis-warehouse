class AddTerminalStatusToCasReports < ActiveRecord::Migration[4.2]
  def change
    add_column :cas_reports, :terminal_status, :string
  end
end
