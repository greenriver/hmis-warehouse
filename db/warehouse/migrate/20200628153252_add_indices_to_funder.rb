class AddIndicesToFunder < ActiveRecord::Migration[5.2]
  def change
    add_index :Funder, [:ProjectID, :Funder]
  end
end
