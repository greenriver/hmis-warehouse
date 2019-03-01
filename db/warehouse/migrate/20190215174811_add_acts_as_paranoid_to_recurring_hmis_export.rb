class AddActsAsParanoidToRecurringHmisExport < ActiveRecord::Migration
  def change
    add_column :recurring_hmis_exports, :deleted_at, :datetime
  end
end
