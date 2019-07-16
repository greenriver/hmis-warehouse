class AddMoveInDateToShe < ActiveRecord::Migration
  def change
    add_column :service_history_enrollments, :move_in_date, :date

    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where.not(MoveInDate: nil).update_all(processed_as: nil)
  end
end
