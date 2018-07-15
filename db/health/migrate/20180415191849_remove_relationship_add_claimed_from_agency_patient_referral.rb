class RemoveRelationshipAddClaimedFromAgencyPatientReferral < ActiveRecord::Migration
  def change
    remove_column :agency_patient_referrals, :relationship, :integer
    add_column :agency_patient_referrals, :claimed, :boolean, null: false, default: false
  end
end
