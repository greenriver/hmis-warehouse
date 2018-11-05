class AddNotesToGlacierArchives < ActiveRecord::Migration
  def change
    add_column :glacier_archives, :notes, :text
    add_column :glacier_archives, :job_id, :string
  end
end
