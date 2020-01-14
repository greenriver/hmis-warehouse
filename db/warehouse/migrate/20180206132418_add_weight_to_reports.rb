class AddWeightToReports < ActiveRecord::Migration[4.2]
  def change
    add_column :report_definitions, :weight, :integer, null: false, default: 0
  end
end
