class MakeReferralUnitTypeOptional < ActiveRecord::Migration[7.0]
  def change
    change_column_null :hmis_external_referral_postings, :unit_type_id, true
  end
end
