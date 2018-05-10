class AddColumnsToEnrollment < ActiveRecord::Migration
  def change
    change_table :Enrollment do |t|
      t.boolean :roi_permission
      t.string  :last_locality
      t.string  :last_zipcode
    end
  end
end
