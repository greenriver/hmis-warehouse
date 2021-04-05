class AddJobIdToUnprocessedEnrollments < ActiveRecord::Migration[5.2]
  def change
    add_reference :Enrollment, :service_history_processing_job
  end
end
