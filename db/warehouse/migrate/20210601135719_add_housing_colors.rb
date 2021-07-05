class AddHousingColors < ActiveRecord::Migration[5.2]
  def change
    add_column :public_report_settings, :location_type_color_0, :string
    add_column :public_report_settings, :location_type_color_1, :string
    add_column :public_report_settings, :location_type_color_2, :string
    add_column :public_report_settings, :location_type_color_3, :string
    add_column :public_report_settings, :location_type_color_4, :string
    add_column :public_report_settings, :location_type_color_5, :string
    add_column :public_report_settings, :location_type_color_6, :string
    add_column :public_report_settings, :location_type_color_7, :string
    add_column :public_report_settings, :location_type_color_8, :string
  end
end
