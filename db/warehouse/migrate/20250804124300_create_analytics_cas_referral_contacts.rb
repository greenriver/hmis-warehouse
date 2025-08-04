class CreateAnalyticsCasReferralContacts < ActiveRecord::Migration[7.1]
  def change
    replace_view 'analytics.cas_referral_contacts', version: 2, revert_to_version: 1
  end
end
