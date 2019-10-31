class RemoveParamsFromActivityLog < ActiveRecord::Migration[4.2]
  def change
    remove_column :activity_logs, :params
  end
end
