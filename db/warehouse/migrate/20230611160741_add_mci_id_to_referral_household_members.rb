class AddMciIdToReferralHouseholdMembers < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_external_referral_household_members, :mci_id, :string
  end
end
