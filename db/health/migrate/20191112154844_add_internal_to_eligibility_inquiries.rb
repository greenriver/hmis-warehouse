class AddInternalToEligibilityInquiries < ActiveRecord::Migration[4.2]
  def change
    add_column :eligibility_inquiries, :internal, :boolean, default: false
  end
end
