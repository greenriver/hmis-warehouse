class AddChangeDescriptionToPatientReferral < ActiveRecord::Migration[5.2]
  def change
    add_column :patient_referrals, :change_description, :string
  end
end
