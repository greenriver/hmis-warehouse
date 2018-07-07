class AddRejectedToPatientReferral < ActiveRecord::Migration
  def change
    add_column :patient_referrals, :rejected, :boolean, null: false, default: false
    add_column :patient_referrals, :rejected_reason, :integer, null: false, default: 0
  end
end
