class AddAgencyToPatientReferral < ActiveRecord::Migration
  def change
    add_column :patient_referrals, :agency_id, :integer
  end
end
