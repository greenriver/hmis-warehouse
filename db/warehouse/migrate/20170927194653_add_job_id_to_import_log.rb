class AddJobIdToImportLog < ActiveRecord::Migration
  def change
    add_reference :uploads, :delayed_job
  end
end
