class AddDeletedAtToAdministrativeEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :administrative_events, :deleted_at, :datetime
    add_index :administrative_events, :deleted_at
  end
end
