class AddEncryptionTypeToRecurringExports < ActiveRecord::Migration[5.2]
  def change
    add_column :recurring_hmis_exports, :encryption_type, :string
  end
end
