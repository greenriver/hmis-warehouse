class AddProcessedHashToEnrollments < ActiveRecord::Migration
  def change
    add_column :Enrollment, :processed_hash, :string
  end
end
