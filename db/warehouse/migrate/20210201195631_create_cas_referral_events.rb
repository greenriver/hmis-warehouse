class CreateCasReferralEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :cas_referral_events do |t|
      t.references :cas_client_id
      t.references :hmis_client_id
      t.references :program_id
      t.references :client_opportunity_match_id
      t.date :referral_date
      t.integer :referral_result
      t.date :referral_result_date

      t.timestamps
    end

    create_table :cas_programs_to_projects do |t|
      t.references :program_id
      t.references :project_id
    end
  end
end
