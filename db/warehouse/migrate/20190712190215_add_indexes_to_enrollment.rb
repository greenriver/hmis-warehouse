class AddIndexesToEnrollment < ActiveRecord::Migration
  def change
    add_index :Enrollment, :MoveInDate
  end
end
