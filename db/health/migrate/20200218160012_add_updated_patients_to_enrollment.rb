class AddUpdatedPatientsToEnrollment < ActiveRecord::Migration[5.2]
  def change
    add_column :enrollments, :updated_patients, :integer
  end
end
