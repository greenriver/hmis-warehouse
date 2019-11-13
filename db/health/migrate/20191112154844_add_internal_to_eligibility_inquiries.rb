class AddInternalToEligibilityInquiries < ActiveRecord::Migration
  def change
    add_column :eligibility_inquiries, :internal, :boolean, default: false
  end
end
