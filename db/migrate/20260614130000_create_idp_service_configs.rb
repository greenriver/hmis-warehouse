###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Creates idp_service_configs in the app DB, next to users and
# user_authentication_sources, which is where the authentication subsystem lives.
class CreateIdpServiceConfigs < ActiveRecord::Migration[7.2]
  def change
    create_table :idp_service_configs do |t|
      t.string :provider, null: false
      t.string :connector_id, null: false
      t.string :name, null: false
      t.string :api_url, null: false

      t.string :encrypted_service_token, null: false
      t.string :encrypted_service_token_iv

      t.string :client_id
      t.string :keycloak_realm
      t.string :okta_org_id

      t.boolean :active, default: true, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :idp_service_configs, [:connector_id, :active, :deleted_at],
              unique: true,
              name: 'index_idp_service_configs_on_connector_active_deleted',
              where: 'active = true AND deleted_at IS NULL'
  end
end
