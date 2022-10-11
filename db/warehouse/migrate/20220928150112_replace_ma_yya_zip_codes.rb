class ReplaceMaYyaZipCodes < ActiveRecord::Migration[6.1]
  def change
    remove_column :ma_yya_report_clients, :zip_code
    add_column :ma_yya_report_clients, :zip_codes, :jsonb, default: []
  end
end
