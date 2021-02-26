class AddFontNamesToPublicReportSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :public_report_settings, :font_family_0, :string
    add_column :public_report_settings, :font_family_1, :string
    add_column :public_report_settings, :font_family_2, :string
    add_column :public_report_settings, :font_family_3, :string
    add_column :public_report_settings, :font_size_0, :string
    add_column :public_report_settings, :font_size_1, :string
    add_column :public_report_settings, :font_size_2, :string
    add_column :public_report_settings, :font_size_3, :string
    add_column :public_report_settings, :font_weight_0, :string
    add_column :public_report_settings, :font_weight_1, :string
    add_column :public_report_settings, :font_weight_2, :string
    add_column :public_report_settings, :font_weight_3, :string
  end
end
