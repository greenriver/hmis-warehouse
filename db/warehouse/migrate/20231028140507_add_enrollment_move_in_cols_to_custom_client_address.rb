class AddEnrollmentMoveInColsToCustomClientAddress < ActiveRecord::Migration[6.1]
  def change
    add_column :CustomClientAddress, :EnrollmentID, :string
  end
end
