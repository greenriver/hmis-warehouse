class AddDeletedAtToPatients < ActiveRecord::Migration
  def change
    add_column :patients, :deleted_at, :datetime
  end
end
