class AddSubmittedAtToVispdats < ActiveRecord::Migration
  def change
    add_column :vispdats, :submitted_at, :timestamp
  end
end
