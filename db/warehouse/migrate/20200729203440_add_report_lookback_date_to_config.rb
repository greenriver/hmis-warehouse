class AddReportLookbackDateToConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :dashboard_lookback, :date, default: '2014-07-01'.to_date
  end
end
