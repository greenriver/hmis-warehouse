class AddWeightToReports < ActiveRecord::Migration
  def change
    add_column :report_definitions, :weight, :integer, null: false, default: 0
  end
end
