# frozen_string_literal: true

class CreateCeReferrals < ActiveRecord::Migration[7.0]
  def change
    create_table(:ce_match_rules) do |t|
      t.string :name, null: false
      t.string :rule_type, null: false
      t.jsonb :applicability_config, null: false
      # what entity manages the configuration
      t.references :owner, null: false, polymorphic: true
      t.string :expression, null: false
      t.timestamps
    end

    # automatically managed candidate pools
    create_table(:ce_match_candidate_pools) do |t|
      t.string :requirement_expression, null: false
      t.string :priority_expression, null: false
      # when was this pool last updated
      t.datetime :configuration_updated_at
      # when were candidates last generated
      t.datetime :candidates_generated_at
      t.timestamps
      t.index [:requirement_expression, :priority_expression], unique: true, name: 'index_ce_match_candidate_pools_uniq'
    end

    # TBD we probably want some kind of association between pools an requirements
    # create_table(:ce_match_pool_requirements) do |t|
    #   t.references :candidate_pool, null: false, foreign_key: { to_table: :ce_match_policies }, index: false
    #   t.references :requirement, null: false, foreign_key: { to_table: :ce_match_requirements}, index: false
    #   t.timestamps
    # end

    create_table(:ce_match_candidates) do |t|
      t.references :candidate_pool, null: false, foreign_key: { to_table: :ce_match_candidate_pools }, index: false
      t.references :client, null: false, foreign_key: { to_table: :Client }
      t.integer :priority_score, null: true
      t.timestamps
      t.index [:candidate_pool_id, :client_id], unique: true, name: 'index_ce_match_candidates_uniq'
    end

    # Opportunities (vacancies or services within projects)
    create_table(:ce_opportunities) do |t|
      t.references :candidate_pool, null: true, foreign_key: { to_table: :ce_match_candidate_pools }
      t.references :project, null: false, comment: 'Project providing this opportunity'
      t.string :workflow_template_identifier, null: false # reference by identifier as the template may be versioned
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
      t.references :user, null: false
      t.jsonb :submitted_form_data
      t.timestamps
    end
  end
end
