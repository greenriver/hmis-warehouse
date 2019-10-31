class AlterHmisExportsProjectIDs < ActiveRecord::Migration[4.2]
  def change
    change_column :exports, :project_ids, :jsonb
  end
end
