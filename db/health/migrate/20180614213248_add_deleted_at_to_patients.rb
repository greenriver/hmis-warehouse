class AddDeletedAtToPatients < ActiveRecord::Migration
  def up
    unless column_exists? :patients, :deleted_at
      add_column :patients, :deleted_at, :datetime
    end
  end
  def down
    if column_exists? :patients, :deleted_at
      remove_column :patients, :deleted_at, :datetime
    end
  end
end
