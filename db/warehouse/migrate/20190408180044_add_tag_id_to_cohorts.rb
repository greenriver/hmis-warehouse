class AddTagIdToCohorts < ActiveRecord::Migration[4.2]
  def change
    add_column :cohorts, :tag_id, :integer
  end
end
