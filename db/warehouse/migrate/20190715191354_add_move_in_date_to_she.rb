class AddMoveInDateToShe < ActiveRecord::Migration
  def change
    add_column :service_history_enrollments, :move_in_date, :date

    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where.not(MoveInDate: nil).update_all(processed_as: nil)
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.unprocessed.pluck(:id).each_slice(250) do |batch|
      Delayed::Job.enqueue(::ServiceHistory::RebuildEnrollmentsByBatchJob.new(enrollment_ids: batch), queue: :low_priority)
    end
  end
end
