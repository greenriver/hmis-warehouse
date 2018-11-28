class AddArchiveNameToGlacierArchives < ActiveRecord::Migration
  def change
    add_column :glacier_archives, :archive_name, :string
  end
end
