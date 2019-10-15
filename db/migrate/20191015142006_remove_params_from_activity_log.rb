class RemoveParamsFromActivityLog < ActiveRecord::Migration
  def change
    remove_column :activity_logs, :params
  end
end
