class AddErrorsToEnrollments < ActiveRecord::Migration[5.2]
  def change
    add_column :enrollments, :processing_errors, :jsonb, default: []
  end
end
