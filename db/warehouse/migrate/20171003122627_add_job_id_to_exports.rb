class AddJobIdToExports < ActiveRecord::Migration[4.2]
  def change
    add_column :exports, :file, :string
    add_column :exports, :delayed_job_id, :integer
  end
end
