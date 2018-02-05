class AddProcessedAsToEnrollment < ActiveRecord::Migration
  def change
    add_column :Enrollment, :processed_as, :string
  end
end
