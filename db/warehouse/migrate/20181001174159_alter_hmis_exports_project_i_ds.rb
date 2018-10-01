class AlterHmisExportsProjectIDs < ActiveRecord::Migration
  def change
    change_column :exports, :project_ids, :jsonb
  end
end
