class AdditionalGenderMultiHudReportFields < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_dq_clients, :gender_multi, :string
    add_column :hud_report_path_clients, :gender_multi, :string
  end
end
