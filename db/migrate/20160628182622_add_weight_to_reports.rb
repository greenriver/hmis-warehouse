class AddWeightToReports < ActiveRecord::Migration
  def change
    add_column :reports, :weight, :integer, null: false, default: 0
  end
end
