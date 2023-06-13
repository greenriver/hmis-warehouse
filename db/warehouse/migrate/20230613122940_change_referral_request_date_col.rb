class ChangeReferralRequestDateCol < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
      change_column :hmis_external_referral_requests, :requested_on, :datetime
    }
  end
end
