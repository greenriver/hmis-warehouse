class AddDefaultReleaseTypeToTags < ActiveRecord::Migration
  def change
    add_column :available_file_tags, :full_release, :boolean, null: false, default: false
  end
end
