###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateIdpServiceConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :idp_service_configs do |t|
      t.string :connector_id, null: false
      t.string :name, null: false
      t.string :api_url, null: false
      t.string :encrypted_service_token, null: false
      t.string :encrypted_service_token_iv

      t.string :org_id
      t.string :project_id
      t.jsonb :additional_config
      t.boolean :active, default: true, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :idp_service_configs, :deleted_at
    add_index :idp_service_configs, [:connector_id, :active, :deleted_at],
              name: 'index_idp_service_configs_on_connector_active_deleted',
              where: 'active = true AND deleted_at IS NULL'
  end
end
