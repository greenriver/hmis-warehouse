class AddVersionToRecurringExports < ActiveRecord::Migration[5.2]
  def change
    add_column :recurring_hmis_exports, :version, :string
  end
end
