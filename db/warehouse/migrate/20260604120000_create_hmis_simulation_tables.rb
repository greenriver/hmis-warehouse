###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateHmisSimulationTables < ActiveRecord::Migration[7.2]
  def change
    # Tracks clients who "belong together" so household composition is
    # preserved across re-enrollments. The HoH's SimulatedClient points here;
    # member client IDs are stored as a JSON array.
    create_table :hmis_simulation_household_groups do |t|
      t.bigint  :data_source_id, null: false
      t.bigint  :hoh_client_id,  null: false
      t.jsonb   :member_client_ids, null: false, default: []
      t.string  :household_template_name
      t.timestamps
    end
    add_index :hmis_simulation_household_groups, :data_source_id
    add_index :hmis_simulation_household_groups, :hoh_client_id

    # One row per simulated client; tracks their current position in the
    # primary enrollment state machine.
    create_table :hmis_simulation_clients do |t|
      t.bigint  :data_source_id,              null: false
      t.bigint  :hud_client_id,               null: false
      t.bigint  :household_group_id
      t.string  :current_population
      t.date    :entered_current_population_at
      t.bigint  :hud_enrollment_id
      t.date    :next_transition_on
      t.date    :pending_enrollment_on
      t.boolean :exited_system, null: false, default: false
      t.timestamps
    end
    add_index :hmis_simulation_clients, :data_source_id
    add_index :hmis_simulation_clients, :hud_client_id
    add_index :hmis_simulation_clients, :next_transition_on
    add_index :hmis_simulation_clients, :pending_enrollment_on
    add_index :hmis_simulation_clients, [:data_source_id, :exited_system]

    # Tracks timed overlapping enrollments (Street Outreach, Services Only,
    # etc.) that run in parallel with the primary enrollment.
    create_table :hmis_simulation_concurrent_enrollments do |t|
      t.bigint  :data_source_id,      null: false
      t.bigint  :hud_client_id,       null: false
      t.bigint  :hud_enrollment_id
      t.string  :project_name
      t.date    :exit_on
      t.date    :pending_reentry_on
      t.timestamps
    end
    add_index :hmis_simulation_concurrent_enrollments, :data_source_id
    add_index :hmis_simulation_concurrent_enrollments, :hud_client_id
    add_index :hmis_simulation_concurrent_enrollments, :exit_on
    add_index :hmis_simulation_concurrent_enrollments, :pending_reentry_on

    # Tracks lifecycle enrollments (e.g. Coordinated Entry) that span
    # multiple primary enrollments and close on a condition rather than a
    # timer.
    create_table :hmis_simulation_lifecycle_enrollments do |t|
      t.bigint  :data_source_id,  null: false
      t.bigint  :hud_client_id,   null: false
      t.bigint  :hud_enrollment_id
      t.string  :lifecycle_name,  null: false
      t.string  :status,          null: false, default: 'pending_open'
      t.date    :opens_on
      t.string  :close_reason
      t.timestamps
    end
    add_index :hmis_simulation_lifecycle_enrollments, :data_source_id
    add_index :hmis_simulation_lifecycle_enrollments, :hud_client_id
    add_index :hmis_simulation_lifecycle_enrollments, :opens_on
    add_index :hmis_simulation_lifecycle_enrollments, [:data_source_id, :status]

    # Audit trail — one row per simulated calendar day per data source.
    # last_successful_run_date is derived as max(run_date) where error_message is null.
    create_table :hmis_simulation_run_logs do |t|
      t.bigint   :data_source_id,       null: false
      t.date     :run_date,             null: false
      t.datetime :started_at
      t.datetime :finished_at
      t.integer  :clients_created,      default: 0
      t.integer  :enrollments_opened,   default: 0
      t.integer  :enrollments_closed,   default: 0
      t.integer  :services_created,     default: 0
      t.text     :error_message
      t.timestamps
    end
    add_index :hmis_simulation_run_logs, :data_source_id
    add_index :hmis_simulation_run_logs, [:data_source_id, :run_date], unique: true
  end
end
