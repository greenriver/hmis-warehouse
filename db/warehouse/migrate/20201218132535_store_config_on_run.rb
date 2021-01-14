class StoreConfigOnRun < ActiveRecord::Migration[5.2]
  def change
    add_column :project_pass_fails, :thresholds, :jsonb, default: {}
  end
end
