class CreatePatientReferralImports < ActiveRecord::Migration[4.2]
  def change
    create_table :patient_referral_imports do |t|
      t.string :file_name, null: false
      t.timestamps null: false
    end
  end
end
