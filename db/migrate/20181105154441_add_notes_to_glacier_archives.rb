class AddNotesToGlacierArchives < ActiveRecord::Migration[4.2]
  def change
    add_column :glacier_archives, :notes, :text
    add_column :glacier_archives, :job_id, :string
  end
end
