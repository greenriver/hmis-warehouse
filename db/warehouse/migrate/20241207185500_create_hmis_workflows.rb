class CreateHmisWorkflows < ActiveRecord::Migration[7.0]
  def change
    create_table :wfd_templates do |t|
      t.string :name, null: false
      t.text :description
      t.references :owner, polymorphic: true # TBD

      t.timestamps
    end

    create_table :wfd_nodes do |t|
      t.references :template, null: false, foreign_key: { to_table: :wfd_templates }
      t.string :type, null: false # For STI
      t.jsonb :trigger_config # when to send notifications, create ce events, state changes, api calls
      t.string :name
      # task nodes have forms
      t.references :form_definition, foreign_key: { to_table: :hmis_form_definitions }
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
      t.string :status, null: false
      t.references :assigned_to
      t.datetime :started_at
      t.datetime :completed_at
      t.json :submitted_values

      t.index [:instance_id, :node_id], unique: true

      t.timestamps
    end
  end
end
