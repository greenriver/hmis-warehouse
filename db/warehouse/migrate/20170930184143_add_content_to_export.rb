class AddContentToExport < ActiveRecord::Migration
  def change
    add_column :exports, :faked_pii, :boolean, default: false
    add_column :exports, :project_ids, :json
    add_column :exports, :include_deleted, :boolean, default: false
    add_column :exports, :content_type, :string
    add_column :exports, :content, :binary
  end
end
