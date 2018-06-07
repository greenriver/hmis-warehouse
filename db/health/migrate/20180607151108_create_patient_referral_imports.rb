class CreatePatientReferralImports < ActiveRecord::Migration
  def change
    create_table :patient_referral_imports do |t|
      t.string :file_name, null: false
      t.timestamps null: false
    end
  end
end
