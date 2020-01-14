class AddWeightToReports < ActiveRecord::Migration[4.2]
  def change
    add_column :reports, :weight, :integer, null: false, default: 0
  end
end
