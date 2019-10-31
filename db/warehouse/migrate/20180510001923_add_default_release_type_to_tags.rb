class AddDefaultReleaseTypeToTags < ActiveRecord::Migration[4.2]
  def change
    add_column :available_file_tags, :full_release, :boolean, null: false, default: false
  end
end
