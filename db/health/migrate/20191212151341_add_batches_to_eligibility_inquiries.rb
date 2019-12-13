class AddBatchesToEligibilityInquiries < ActiveRecord::Migration
  def change
    add_column :eligibility_inquiries, :batch_id, :integer, default: nil
    add_index :eligibility_inquiries, :batch_id
  end
end
