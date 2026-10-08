###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateClientRetentionExpiringClients < ActiveRecord::Migration[7.2]
  def change
    # Identifiers only, rewritten by each ClientRetentionJob run; the report reads the rows of
    # the latest completed run by run_id alone.
    create_table :client_retention_expiring_clients do |t|
      t.references :run, null: false, index: false
      t.bigint :destination_client_id, null: false
      t.jsonb :source_clients, null: false, default: []
      t.date :last_activity_on, null: false
      t.integer :retention_years, null: false
      t.string :basis, null: false
      t.date :expires_on, null: false
      t.index [:run_id, :expires_on], name: 'index_client_retention_expiring_on_run_id_and_expires_on'
    end
  end
end
