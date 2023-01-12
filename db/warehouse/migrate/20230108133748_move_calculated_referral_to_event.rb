class MoveCalculatedReferralToEvent < ActiveRecord::Migration[6.1]
  def change
    remove_column :custom_imports_b_services_rows, :calculated_referral_result, :integer
    remove_column :custom_imports_b_services_rows, :calculated_referral_date, :date
    add_column :synthetic_events, :calculated_referral_result, :integer
    add_column :synthetic_events, :calculated_referral_date, :date
  end
end
