###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateClientRetentionTables < ActiveRecord::Migration[7.2]
  def change
    # One row per aged-out source client. Destination clients are resolved through
    # warehouse_clients at query time (see GrdaWarehouse::HiddenClients).
    create_table :inactive_clients do |t|
      t.bigint :client_id, null: false
      t.date :marked_on, null: false
      t.date :last_activity_on, null: false
      t.integer :retention_years, null: false
      t.index :client_id, unique: true
    end

    create_table :client_retention_runs do |t|
      t.timestamp :started_at, null: false
      t.timestamp :completed_at
      t.integer :global_retention_years, null: false
      t.jsonb :data_source_overrides, null: false, default: {}
      t.integer :evaluated_count, null: false, default: 0
      t.integer :marked_count, null: false, default: 0
      t.integer :unmarked_count, null: false, default: 0
      t.timestamps
    end

    # Plain identifiers only, never names, SSN or DOB, so the log outlives the client rows
    # without becoming a copy of the PII it records the removal of.
    create_table :client_retention_log_entries do |t|
      t.references :run, null: false, index: true
      t.string :action, null: false
      t.bigint :destination_client_id, null: false, index: true
      t.jsonb :source_clients, null: false, default: []
      t.date :last_activity_on
      t.integer :retention_years
      t.timestamp :created_at, null: false
    end

    # Not concurrent, so the migration stays in one transaction (see the
    # warehouse_clients_processed unique-index migration for why).
    safety_assured do
      add_index :files, :client_id, if_not_exists: true
      add_index :CustomAssessments, [:data_source_id, :PersonalID], if_not_exists: true
    end
  end
end
