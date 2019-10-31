class RenamePatientReferralUpdatedOn < ActiveRecord::Migration[4.2][4.2]
  def change
    rename_column :patient_referrals, :updated_on, :record_updated_on
  end
end
