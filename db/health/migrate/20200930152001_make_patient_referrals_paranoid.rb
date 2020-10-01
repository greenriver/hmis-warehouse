class MakePatientReferralsParanoid < ActiveRecord::Migration[5.2]
  def change
    add_column :patient_referrals, :deleted_at, :datetime
    add_column :agency_patient_referrals, :deleted_at, :datetime
  end
end
