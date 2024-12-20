class CreateCeReferrals < ActiveRecord::Migration[7.0]
  def change
    # Opportunities (vacancies or services within projects)
    create_table(:ce_opportunities) do |t|
      t.timestamps
      t.references :project, null: false # what project provides this opportunity?
      t.references :workflow_template, null: false, foreign_key: { to_table: :wfd_templates }
      t.string :name, null: false
      t.string :status, null: false
      t.jsonb :requirements_config # Specific requirements for this opportunity
      t.datetime :expires_at
    end

    # Referrals (instances of clients going through workflow)
    create_table(:ce_referrals) do |t|
      t.timestamps
      t.references :opportunity, null: false, foreign_key: { to_table: :ce_opportunities }
      t.references :workflow_instance, null: false, foreign_key: { to_table: :wfe_instances }
      t.string :status, null: false
      t.references :client, null: false
      t.references :referred_by
      t.datetime :completed_at
    end

    create_table(:ce_referral_notes) do |t|
      t.timestamps
      t.references :referral, null: false, foreign_key: { to_table: :ce_referrals }
      t.references :submitted_by, null: false
      t.jsonb :submitted_form_data
    end
  end
end
