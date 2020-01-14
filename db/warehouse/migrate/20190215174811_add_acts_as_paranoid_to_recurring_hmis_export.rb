class AddActsAsParanoidToRecurringHmisExport < ActiveRecord::Migration[4.2]
  def change
    add_column :recurring_hmis_exports, :deleted_at, :datetime
  end
end
