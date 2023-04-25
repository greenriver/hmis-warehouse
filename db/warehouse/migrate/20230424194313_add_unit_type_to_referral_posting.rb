class AddUnitTypeToReferralPosting < ActiveRecord::Migration[6.1]
  def change
    add_reference :hmis_external_referral_postings, :unit_type, null: false, foreign_key: { to_table: :hmis_unit_types }
  end
end
