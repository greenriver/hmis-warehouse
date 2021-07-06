class AddColorsForStateDashboards < ActiveRecord::Migration[5.2]
  def change
    add_column :public_report_settings, :summary_color, :string
    add_column :public_report_settings, :homeless_primary_color, :string
    add_column :public_report_settings, :youth_primary_color, :string
    add_column :public_report_settings, :adults_only_primary_color, :string
    add_column :public_report_settings, :adults_with_children_primary_color, :string
    add_column :public_report_settings, :children_only_primary_color, :string
    add_column :public_report_settings, :veterans_primary_color, :string
  end
end
