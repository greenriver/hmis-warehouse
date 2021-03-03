class AddJobIdToUnprocessedEnrollments < ActiveRecord::Migration[5.2]
  def change
    add_reference :Enrollment, :delayed_job
  end
end
