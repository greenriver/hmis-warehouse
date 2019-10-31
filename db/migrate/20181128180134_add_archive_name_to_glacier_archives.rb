class AddArchiveNameToGlacierArchives < ActiveRecord::Migration[4.2]
  def change
    add_column :glacier_archives, :archive_name, :string
  end
end
