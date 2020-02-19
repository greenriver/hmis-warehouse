class AddDeletedAtToDataSources < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sources, :deleted_at, :datetime, index: true
  end
end
