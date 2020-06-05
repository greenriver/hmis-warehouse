class AddMultipleReferralFields < ActiveRecord::Migration[5.2]
  def change
    change_table :patient_referrals do |t|
      t.boolean :current, null: false, default: false, index: true
      t.boolean :contributing, null: false, default: false, index: true
    end
  end
end
