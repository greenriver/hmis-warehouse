class CreateCasReferralEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :cas_referral_events do |t|
      t.references :cas_client
      t.references :hmis_client
      t.references :program
      t.references :client_opportunity_match
      t.date :referral_date
      t.integer :referral_result
      t.date :referral_result_date

      t.timestamps
    end

    create_table :cas_programs_to_projects do |t|
      t.references :program
      t.references :project
    end
  end
end
