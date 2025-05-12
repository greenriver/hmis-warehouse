class AddIndexToPatientReferrals < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_index :patient_referrals, [:patient_id, :current]
    end
  end
end
