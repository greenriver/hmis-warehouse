class AddFlexFundsToMaYyaReportClient < ActiveRecord::Migration[6.1]
  def change
    add_column :ma_yya_report_clients, :flex_funds, :jsonb, default: []
  end
end
