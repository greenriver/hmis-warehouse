class AddProcessedAsToEnrollment < ActiveRecord::Migration[4.2]
  def change
    add_column :Enrollment, :processed_as, :string
  end
end
