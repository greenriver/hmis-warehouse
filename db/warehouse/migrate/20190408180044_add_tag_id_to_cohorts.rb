class AddTagIdToCohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :tag_id, :integer
  end
end
