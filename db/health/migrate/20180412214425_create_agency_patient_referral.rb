class CreateAgencyPatientReferral < ActiveRecord::Migration
  def change
    create_table :agency_patient_referrals do |t|
      t.integer :agency_id, null: false
      t.integer :patient_referral_id, null: false
      t.integer :relationship, default: 0
    end
  end
end
