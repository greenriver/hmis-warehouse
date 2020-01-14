class AddProcessedHashToEnrollments < ActiveRecord::Migration[4.2]
  def change
    add_column :Enrollment, :processed_hash, :string
  end
end
