class AddRejectedToPatientReferral < ActiveRecord::Migration[4.2]
  def change
    add_column :patient_referrals, :rejected, :boolean, null: false, default: false
    add_column :patient_referrals, :rejected_reason, :integer, null: false, default: 0
  end
end
