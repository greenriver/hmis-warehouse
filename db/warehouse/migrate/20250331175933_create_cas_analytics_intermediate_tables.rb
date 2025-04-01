
# frozen_string_literal: true

class CreateCasAnalyticsIntermediateTables < ActiveRecord::Migration[7.0]
  def change
    # Representation of sub-programs
    create_table :cas_analytics_opportunity_categories do |t|
      t.string :full_name, comment: 'concatenation of program name and sub-program name'
      t.string :name
      t.string :sub_project_name
      t.string :program_type
      t.references :subgrantee, index: false
      t.string :subgrantee_name
      t.references :sub_contractor, index: false
      t.string :sub_contractor_name
      t.references :hsa, index: false
      t.string :hsa_name

      t.timestamps
    end

    create_table :cas_analytics_opportunities do |t|
      t.references :cas_analytics_opportunity_category, index: false
      t.boolean :available

      t.timestamps
    end

    create_table :cas_analytics_clients do |t|
      t.references :client, index: false
      t.date :calculated_first_homeless_night
      t.date :calculated_last_homeless_night

      t.timestamps
    end

    create_table :cas_analytics_workflow_contacts do |t|
      t.string :email
      t.references :cas_analytics_workflow, index: false
      t.references :cas_analytics_contact, index: false
      t.string :contact_type

      t.timestamps
    end

    create_table :cas_analytics_cas_users do |t|
      t.string :email
      t.references :agency, index: false
      t.string :agency_name

      t.timestamps
    end

    # Representation of client-opportunity-match combined with route
    create_table :cas_analytics_workflows do |t|
      t.string :workflow_name
      t.references :cas_analytics_clients, index: false
      t.references :client, index: false
      t.references :cas_analytics_workflows, index: false
      t.datetime :started_at
      t.datetime :completed_at
      t.string :terminal_status

      t.timestamps
    end

    # Representation of decisions
    create_table :cas_analytics_steps do |t|
      t.references :cas_analytics_workflow, index: false
      t.string :name
      t.integer :order
      t.string :status
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    # Used to determine which users can see which workflow instances
    create_table :cas_analytics_workflow_users do |t|
      t.string :email
      t.references :cas_analytics_workflow, index: false
    end
  end
end
