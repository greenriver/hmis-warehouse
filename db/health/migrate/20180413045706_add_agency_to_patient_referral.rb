class AddAgencyToPatientReferral < ActiveRecord::Migration[4.2]
  def change
    add_column :patient_referrals, :agency_id, :integer
  end
end
