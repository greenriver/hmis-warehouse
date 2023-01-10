class AddReferralDetailsTobRows < ActiveRecord::Migration[6.1]
  def change
    add_column :custom_imports_b_services_rows, :calculated_referral_result, :integer
    add_column :custom_imports_b_services_rows, :calculated_referral_date, :date
  end
end
