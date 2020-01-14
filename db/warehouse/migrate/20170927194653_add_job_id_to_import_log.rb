class AddJobIdToImportLog < ActiveRecord::Migration[4.2]
  def change
    add_reference :uploads, :delayed_job
  end
end
