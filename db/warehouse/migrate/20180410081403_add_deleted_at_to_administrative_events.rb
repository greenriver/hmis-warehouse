class AddDeletedAtToAdministrativeEvents < ActiveRecord::Migration
  def change
    add_column :administrative_events, :deleted_at, :datetime
    add_index :administrative_events, :deleted_at
  end
end
