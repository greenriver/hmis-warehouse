class AddPlacedDateToAnsdEnrollments < ActiveRecord::Migration[6.1]
  def change
    add_column :ansd_enrollments, :placed_date, :date
  end
end
