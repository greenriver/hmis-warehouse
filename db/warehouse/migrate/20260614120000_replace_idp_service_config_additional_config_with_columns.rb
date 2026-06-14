###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Replaces the free-form additional_config JSONB with discrete client_id/realm
# columns. The JSONB only ever held those two Keycloak keys, and accepting an
# arbitrary hash through strong params tripped the mass-assignment scanner.
#
# Also tightens the indexes: drops the low-selectivity standalone deleted_at
# index, and makes the connector/active/deleted_at partial index unique so the
# DB enforces what the model's uniqueness validation already asserts.
class ReplaceIdpServiceConfigAdditionalConfigWithColumns < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      # client_id is a generic OIDC concept shared by every provider; realm is
      # Keycloak-specific, so it's namespaced to signal it only applies when
      # connector_id = 'keycloak'.
      add_column :idp_service_configs, :client_id, :string
      add_column :idp_service_configs, :keycloak_realm, :string

      # JSONB always stores string keys, so ->> is sufficient. Raw SQL avoids
      # loading the model (and its attr_encrypted/validations) during migration.
      execute(<<~SQL.squish)
        UPDATE idp_service_configs
        SET client_id = additional_config ->> 'client_id',
            keycloak_realm = additional_config ->> 'realm'
        WHERE additional_config IS NOT NULL
      SQL

      remove_column :idp_service_configs, :additional_config

      remove_index :idp_service_configs, :deleted_at

      remove_index :idp_service_configs, name: 'index_idp_service_configs_on_connector_active_deleted'
      add_index :idp_service_configs, [:connector_id, :active, :deleted_at],
                unique: true,
                name: 'index_idp_service_configs_on_connector_active_deleted',
                where: 'active = true AND deleted_at IS NULL'
    end
  end
end
