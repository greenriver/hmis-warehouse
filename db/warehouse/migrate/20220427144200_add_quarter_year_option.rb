class AddQuarterYearOption < ActiveRecord::Migration[6.1]
  def change
    add_column :public_report_settings, :iteration_type, :string, default: :quarter, null: false
  end
end
