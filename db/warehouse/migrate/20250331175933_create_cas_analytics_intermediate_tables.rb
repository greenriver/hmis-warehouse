
# frozen_string_literal: true

class CreateCasAnalyticsIntermediateTables < ActiveRecord::Migration[7.0]
  def change

    create_table :cas_analytics_agencies do |t|
      t.string :name
      t.timestamps
    end

    create_table :cas_analytics_subgrantees do |t|
      t.string :name
      t.boolean :disabled
      t.timestamps
    end

    # Representation of sub-programs
    create_table :cas_analytics_projects do |t|
      t.string :full_name, comment: 'concatenation of program name and sub-program name'
      t.string :name
      t.string :sub_project_name
      t.string :program_type
      t.references :subgrantee
      t.references :sub_contractor
      t.references :hsa

      t.timestamps
    end

    create_table :cas_analytics_opportunities do |t|
      t.references :cas_analytics_project
      t.boolean :available

      t.timestamps
    end

    create_table :cas_analytics_clients do |t|
      t.references :client
      t.date :calculated_first_homeless_night
      t.date :calculated_last_homeless_night

      t.timestamps
    end

    create_table :cas_analytics_workflow_instance_contacts do |t|
      t.string :email
      t.references :cas_analytics_instance, index: { name: "idx_cai_contacts_on_cai_id" }
      t.references :cas_analytics_contacts, index: { name: "idx_cai_contacts_on_cac_id" }
      t.string :contact_type

      t.timestamps
    end

    create_table :cas_analytics_cas_user do |t|
      t.string :email
      t.references :cas_analytics_agencies

      t.timestamps
    end

    # Representation of client-opportunity-match
    create_table :cas_analytics_instance do |t|
      t.string :workflow_name
      t.references :cas_analytics_clients
      t.references :client
      t.references :cas_analytics_workflows

      t.timestamps
    end

    # Representation of decisions
    create_table :cas_analytics_steps do |t|
      t.references :cas_analytics_instance
      t.string :name
      t.integer :order
      t.string :status
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    # Used to determine which users can see which instances
    create_table :cas_analytics_instance_user do |t|
      t.string :email
      t.references :cas_analytics_instance
    end
  end
end
