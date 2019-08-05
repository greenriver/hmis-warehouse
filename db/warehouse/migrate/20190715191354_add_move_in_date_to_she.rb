class AddMoveInDateToShe < ActiveRecord::Migration
  def change
    add_column :service_history_enrollments, :move_in_date, :date

  end
end
