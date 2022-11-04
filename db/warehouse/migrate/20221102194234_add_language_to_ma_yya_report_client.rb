class AddLanguageToMaYyaReportClient < ActiveRecord::Migration[6.1]
  def change
    add_column :ma_yya_report_clients, :language, :string
  end
end
