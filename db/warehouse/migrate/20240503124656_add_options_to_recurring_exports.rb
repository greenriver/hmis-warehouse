class AddOptionsToRecurringExports < ActiveRecord::Migration[7.0]
  def change
    add_column :recurring_hmis_exports, :options, :jsonb
  end
end
