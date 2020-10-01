class AddHealthFlagToWarehouseReports < ActiveRecord::Migration[5.2]
  def change
    add_column :report_definitions, :health, :boolean, default: false
  end
end
