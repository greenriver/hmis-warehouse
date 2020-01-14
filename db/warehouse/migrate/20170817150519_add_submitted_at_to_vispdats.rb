class AddSubmittedAtToVispdats < ActiveRecord::Migration[4.2]
  def change
    add_column :vispdats, :submitted_at, :timestamp
  end
end
