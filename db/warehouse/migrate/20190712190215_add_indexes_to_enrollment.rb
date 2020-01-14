class AddIndexesToEnrollment < ActiveRecord::Migration[4.2]
  def change
    add_index :Enrollment, :MoveInDate
  end
end
