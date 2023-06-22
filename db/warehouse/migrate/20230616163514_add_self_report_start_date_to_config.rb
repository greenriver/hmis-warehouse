class AddSelfReportStartDateToConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :self_report_start_date, :date
  end
end
