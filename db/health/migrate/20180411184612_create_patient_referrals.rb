class CreatePatientReferrals < ActiveRecord::Migration
  def change
    create_table :patient_referrals do |t|
      t.string :first_name
      t.string :last_name
      t.date :birthdate
      t.string :ssn
      t.string :medicaid_id
      t.timestamps null: false
    end
  end
end
