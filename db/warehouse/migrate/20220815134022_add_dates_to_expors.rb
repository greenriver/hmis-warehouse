class AddDatesToExpors < ActiveRecord::Migration[6.1]
  def change
    add_column :exports, :started_at, :datetime
    add_column :exports, :completed_at, :datetime
    add_column :exports, :options, :jsonb
  end
end
