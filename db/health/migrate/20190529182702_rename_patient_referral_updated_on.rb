class RenamePatientReferralUpdatedOn < ActiveRecord::Migration
  def change
    rename_column :patient_referrals, :updated_on, :record_updated_on
  end
end
