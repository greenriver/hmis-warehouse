# frozen_string_literal: true

class CreateHmisWorkflows < ActiveRecord::Migration[7.0]
  def change
    create_table :wfd_templates do |t|
      t.string :identifier, null: false
      t.string :name, null: false
      t.integer :version, null: false
      t.string :status, null: false # retired, published, draft
      t.text :description
      t.references :owner, polymorphic: true # TBD

      t.index :identifier, unique: true, where: "status = 'published'", name: 'index_templates_on_identifier_published'

      t.timestamps
    end

    create_table :wfd_swimlanes do |t|
      t.references :template, null: false, foreign_key: { to_table: :wfd_templates }
      t.string :name, null: false
      t.timestamps
    end

    create_table :wfd_nodes do |t|
      t.references :template, null: false, foreign_key: { to_table: :wfd_templates }
      t.string :type, null: false # For STI
      t.jsonb :trigger_config # when to send notifications, create ce events, state changes, api calls
      t.string :name
      t.references :swimlane, foreign_key: { to_table: :wfd_swimlanes }
      # task nodes have forms.
      t.string :form_definition_identifier
      # gateway nodes have types
      t.string :gateway_type

      t.timestamps
    end

    create_table :wfd_flows do |t|
      t.references :template, null: false, foreign_key: { to_table: :wfd_templates }
      t.references :source_node, null: false, foreign_key: { to_table: :wfd_nodes }, index: false
      t.references :target_node, null: false, foreign_key: { to_table: :wfd_nodes }
      t.string :condition
      t.integer :position, null: false, default: 0
      t.index [:source_node_id, :target_node_id], unique: true

      t.timestamps
    end

    create_table :wfe_instances do |t|
      t.references :template, null: false, foreign_key: { to_table: :wfd_templates }

      t.timestamps
    end

    create_table :wfe_steps do |t|
      t.references :instance, null: false, foreign_key: { to_table: :wfe_instances }
      t.references :node, null: false, foreign_key: { to_table: :wfd_nodes }
      t.references :form_definition, foreign_key: { to_table: :hmis_form_definitions }, null: true
      t.boolean :reversible, null: false, default: true
      t.string :status, null: false
      t.references :assigned_to
      t.datetime :started_at
      t.datetime :completed_at
      t.json :submitted_values

      t.index [:instance_id, :node_id], unique: true

      t.timestamps
    end

    create_table :wfe_step_assignments do |t|
      t.references :step, null: false, foreign_key: { to_table: :wfe_steps }
      t.references :user, null: false, index: false # no fk due to db boundary
      t.index [:user_id, :step_id], unique: true

      t.timestamps
    end

    create_table :wfe_audit_events do |t|
      t.references :instance, null: false, foreign_key: { to_table: :wfe_instances }
      t.references :step, null: true, foreign_key: { to_table: :wfe_steps }
      t.references :user, null: true, index: false # no fk due to db boundary
      t.string :event_type, null: false
      t.json :event_data, null: true

      t.timestamps
    end
  end
end
