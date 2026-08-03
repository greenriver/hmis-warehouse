###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Columns that let the DB row be the single source of truth for an IdP connector,
# so ENV is read only once at seed time (see SeedMaker#seed_idp_service_config).
#
# - manage_users:      whether we have admin/manage-API access to this realm. Default
#                      true keeps existing rows admin-managed; false is authenticate-only.
# - browser_url:       public origin for the account console / AIA deep-links, per realm.
# - account_client_id: OIDC client an application-initiated action runs under.
class AddIdpServiceConfigCapabilityColumns < ActiveRecord::Migration[7.2]
  def change
    add_column :idp_service_configs, :manage_users, :boolean, default: true, null: false
    add_column :idp_service_configs, :browser_url, :string
    add_column :idp_service_configs, :account_client_id, :string
  end
end
