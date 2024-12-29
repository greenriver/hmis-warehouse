class CreateCeReferrals < ActiveRecord::Migration[7.0]
  def change
    # configuration for which clients are eligible and how they are prioritized for opportunities
    create_table(:ce_client_match_policies) do |t|
      # t.references :owner, null: false, polymorphic: true
      t.string :name, null: false
      # 'vispdat_score + IF(veteran_status = 1, 100, 0)'
      t.string :prioritization_formula
      # 'current_age > 18 AND days_homeless > 365'
      t.string :eligibility_requirements
      t.timestamps
    end

    # Candidates that are eligible and prioritized against a policy
    create_table(:ce_client_match_candidates) do |t|
      t.references :match_policy, null: false, foreign_key: { to_table: :ce_client_match_policies }, index: false
      t.references :client, null: false, foreign_key: { to_table: :Client }
      t.integer :priority_score, null: true
      t.index [:match_policy_id, :client_id], unique: true, name: 'index_ce_client_match_candidates_uniq'
      t.timestamps
    end

    # Opportunities (vacancies or services within projects)
    create_table(:ce_opportunities) do |t|
      t.references :project, null: false # what project provides this opportunity?
      t.references :match_policy, null: true, foreign_key: { to_table: :ce_client_match_policies }
      t.string :workflow_template_identifier, null: false # use an identifier to allow
      t.string :name, null: false
      t.string :status, null: false
      t.datetime :expires_at
      t.timestamps
    end

    create_table(:ce_opportunity_categories) do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table(:ce_opportunity_categorizations) do |t|
      t.references :opportunity, null: false, foreign_key: { to_table: :ce_opportunities }, index: false
      t.references :category, null: false, foreign_key: { to_table: :ce_opportunity_categories }
      t.index [:opportunity_id, :category_id], unique: true, name: 'index_ce_opportunity_categorizations_uniq'
      t.timestamps
    end

    # Referrals (instances of clients going through workflow)
    create_table(:ce_referrals) do |t|
      t.references :opportunity, null: false, foreign_key: { to_table: :ce_opportunities }
      t.references :workflow_instance, null: false, foreign_key: { to_table: :wfe_instances }
      t.string :status, null: false
      t.references :client, null: false
      t.references :referred_by
      t.datetime :completed_at
      t.timestamps
    end

    create_table(:ce_referral_participants) do |t|
      t.references :referral, null: false, foreign_key: { to_table: :ce_referrals }
      t.references :user, null: false
      t.references :swimlane, null: true, foreign_key: { to_table: :wfd_swimlanes }
      t.timestamps
    end

    create_table(:ce_referral_notes) do |t|
      t.references :referral, null: false, foreign_key: { to_table: :ce_referrals }
      t.references :participant, null: false, foreign_key: { to_table: :ce_referral_participants }
      t.jsonb :submitted_form_data
      t.timestamps
    end
  end
end
